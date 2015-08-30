require 'droplet_ctl/api_endpoint'

module DropletCtl
  class Action < APIEndpoint
    class Error < RuntimeError; end

    def self.path
      'actions'
    end

    def wait
      status = nil
      loop do
        info = self.info
        status = info['status']
        case status
        when 'completed' then break
        when 'errored' then fail Error, "failed completing action: #{info}"
        end
      end
      status
    end
  end
end
