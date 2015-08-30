require 'droplet_ctl/api_endpoint'

module DropletCtl
  class Image < APIEndpoint
    def self.path
      'images'
    end
  end
end
