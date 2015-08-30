require 'droplet_ctl/api_endpoint'
require 'droplet_ctl/actions'
require 'droplet_ctl/image'

module DropletCtl
  class Droplet < APIEndpoint
    include Actions
    def self.path
      'droplets'
    end

    def networks(version = :v4)
      if version != :v4 && version != :v6
        fail ArgumentError, 'version must be either :v4 or :v6'
      end
      info['networks'][version.to_s]
    end

    def ip_addresses(version = :v4)
      networks(version).map { |network| network['ip_address'] }
    end

    def status
      info['status'].to_sym
    end

    def shutdown
      return unless status == :active
      trigger('shutdown')
    end

    def create_snapshot(name)
      shutdown && shutdown.wait
      trigger('snapshot', name: name)
    end

    def self.create(name, region, size, image, options)
      response = post_request(
        path,
        {
          name: name,
          region: region,
          size: size,
          image: image.id
        }.merge(options)
      )
      Action.new(response['links']['actions'].first['id'])
    end
  end
end
