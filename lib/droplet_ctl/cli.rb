require 'droplet_ctl/api'
require 'droplet_ctl/droplet'
require 'droplet_ctl/image'
require 'optparse'

module DropletCtl
  class CLI
    attr_reader :options

    def initialize
      @options = {}
      abort_with_error('no api token set') unless DropletCtl::API::TOKEN
    end

    def perform_action
      option_parser.parse!
      puts options
      case options[:target]
      when 'droplet' then perform_droplet_action
      when 'snapshot' then perform_snapshot_action
      when nil then abort("No target specified\n#{option_parser.to_s}")
      else abort("Invalid target #{options[:target]}\n#{option_parser.to_s}")
      end
    end

    def perform_droplet_action
      case options[:action]
      when 'list' then perform_droplet_list_action
      when 'create' then perform_droplet_create_action
      when 'destroy' then perform_droplet_destroy_action
      when 'rename' then perform_droplet_rename_action
      when nil then abort("No action specified\n#{option_parser.to_s}")
      else abort("Invalid action #{options[:action]}\n#{option_parser.to_s}")
      end
    end

    def perform_snapshot_action
      case options[:action]
      when 'list' then perform_snapshot_list_action
      when 'create' then perform_snapshot_create_action
      when 'destroy' then perform_snapshot_destroy_action
      when 'rename' then perform_snapshot_rename_action
      when nil then abort("No action specified\n#{option_parser.to_s}")
      else abort("Invalid action #{options[:action]}\n#{option_parser.to_s}")
      end
    end

    def perform_droplet_create_action
      %i(name size region snapshot).each do |option|
        abort_with_error("No #{option} specified") unless options[option]
      end
      snapshot = Image.find_by({ name: options[:snapshot] }, private: true)
      abort("No snapshot found for name #{options[:snapshot]}") unless snapshot
      create_options[:ipv6] = options[:ipv6]
      create_options[:backups] = options[:backups]
      create_options[:private_networking] = [:private_networking]
      puts(new_droplet_message(create_options))
      exit unless gets =~ /^y/i

      action = Droplet.create(
        options[:name].to_s,
        options[:region].to_s,
        options[:size].to_s,
        snapshot,
        create_options
      )
      action.wait if options[:wait]
    end

    def perform_droplet_destroy_action
      abort_with_error('No droplet specified') unless options[:droplet]
      droplet = Droplet.find_by(name: options[:droplet])
      abort("No droplet found for name #{options[:droplet]}") unless droplet
      puts(
        "This will permanently destroy your droplet #{options[:droplet]}\n" \
        'Are you sure you want to continue? (y/N)'
      )
      exit unless gets =~ /^y/i
      droplet.destroy
    end

    def perform_droplet_rename_action
      %i(droplet name).each do |option|
        abort_with_error("No #{option} specified") unless options[option]
      end
      droplet = Droplet.find_by(name: options[:droplet])
      abort("No droplet found for name #{options[:droplet]}") unless droplet
      puts(
        "This will rename your droplet #{options[:droplet]} to #{options[:name]}\n" \
        'Sounds good? (y/N)'
      )
      exit unless gets =~ /^y/i
      droplet.update(name: options[:name])
    end

    def perform_snapshot_create_action
      %i(droplet name).each do |option|
        abort_with_error('No droplet specified') unless options[option]
      end
      droplet = Droplet.find_by(name: options[:droplet])
      abort("No droplet found for name #{options[:droplet]}") unless droplet
      puts(
        "This will create a new snapshot #{options[:name]} for #{options[:droplet]}\n" \
        'Sounds good? (y/N)'
      )

      exit unless gets =~ /^y/i
      action = droplet.create_snapshot(options[:name])
      action.wait if options[:wait]
    end

    def perform_snapshot_destroy_action
      abort_with_error('No snapshot specified') unless options[:snapshot]
      snapshot = Image.find_by({ name: options[:snapshot] }, private: true)
      abort("No snapshot found for name #{options[:snapshot]}") unless snapshot
      puts(
        "This will permanently destroy your snapshot #{options[:snapshot]}\n" \
        'Are you sure you want to continue? (y/N)'
      )
      exit unless gets =~ /^y/i
      snapshot.destroy
    end

    def perform_snapshot_rename_action
      %i(snapshot name).each do |option|
        abort_with_error('No snapshot specified') unless options[option]
      end
      snapshot = Image.find_by({ name: options[:snapshot] }, private: true)
      abort("No snapshot found for name #{options[:snapshot]}") unless snapshot
      puts(
        "This will rename your snapshot #{options[:snapshot]} to #{options[:name]}\n" \
        'Sounds good? (y/N)'
      )

      exit unless gets =~ /^y/i
      snapshot.update(name: options[:name])
    end

    def perform_snapshot_list_action
      Image.all(private: true).each do |image|
        puts("id: #{image['id']}, name: #{image['name']}")
      end
    end

    def perform_droplet_list_action
      Droplet.all.each do |droplet|
        puts("id: #{droplet['id']}, name: #{droplet['name']}, status: #{droplet['status']}")
      end
    end

    private

    def option_parser
      @option_parser ||= begin
        valid_actions = %w(list create rename destroy)
        valid_targets = %w(droplet snapshot)
        OptionParser.new do |parser|
          parser.banner = "Usage: #{$PROGRAM_NAME} <options...>"
          parser.separator("\nAvailable options:")
          parser.on(
            '-a', '--action ACTION',
            "action to perform. one of (#{valid_actions.join('|')})"
          ) do |action|
            @options[:action] = action
          end

          parser.on(
            '-t', '--target TARGET',
            "target to perform the action on. one of (#{valid_targets.join('|')})"
          ) do |target|
            @options[:target] = target
          end

          parser.on(
            '-d', '--droplet DROPLET',
            'name of the droplet associated with the action'
          ) do |name|
            @options[:droplet] = name
          end

          parser.on(
            '-s', '--snapshot SNAPSHOT',
            'name of the snapshot associated with the action'
          ) do |name|
            @options[:snapshot] = name
          end

          parser.on(
            '-w', '--wait',
            'wait for the action to finish'
          ) do
            @options[:wait] = true
          end

          parser.separator("\nOptions for the create action:")

          parser.on('-n', '--name NAME', 'new name for the target') do |name|
            @options[:name] = name
          end

          parser.separator("\ndroplet target only:")

          parser.on('-s', '--size SIZE', 'size for the new droplet') do |size|
            @options[:size] = size
          end

          parser.on('-r', '--region REGION', 'region for the new droplet') do |region|
            @options[:size] = region
          end

          parser.on('-6', '--ipv6', 'set up ipv6 network') do
            @options[:ipv6] = true
          end

          parser.on('-p', '--private-networking', 'set up private networking') do
            @options[:private_networking] = true
          end

          parser.separator('\nEnvironment variables:')

          parser.on('DIGITAL_OCEAN_API_TOKEN', 'your api token') {}

          parser.separator(<<EOF
\nExamples:
# Destroy a droplet:
$ #{$PROGRAM_NAME} -a destroy -t droplet -d 'my droplet'

# Create a snapshot:
$ #{$PROGRAM_NAME} -a create -t snapshot -d 'my droplet' -n 'my new snapshot'

# Restore a droplet from a snapshot:
$ #{$PROGRAM_NAME} -a create -t droplet -n 'my droplet' -s 512mb -6 -r nyc3 -s 'my snapshot

# Update a snapshot:
$ #{$PROGRAM_NAME} -a rename -t snapshot -s 'my snapshot' -n 'my snapshot backup'
$ #{$PROGRAM_NAME} -a create -t snapshot -d 'my droplet' -n 'my snapshot'
$ #{$PROGRAM_NAME} -a destroy -t snapshot -s 'my snapshot backup'
EOF
          )
        end
      end
    end

    private

    def abort_with_error(message)
      abort("#{message}\n#{option_parser}")
    end

    def new_droplet_message(create_options)
      <<EOF
This will create a new droplet with the following configuration
name: #{options[:name]}
size: #{options[:size]}
region: #{options[:region]}
image: #{snapshot.id} (#{snapshot.name})
ipv6: #{create_options[:ipv6]}
backups: #{create_options[:backups]}
private_networking: #{create_options[:private_networking]}

Sounds good? (y/N)
EOF
    end
  end
end
