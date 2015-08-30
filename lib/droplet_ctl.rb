require 'droplet_ctl/version'
require 'droplet_ctl/cli'

module DropletCtl
  def self.run
    DropletCtl::CLI.new.perform_action
  end
end
