require 'droplet_ctl/api'
require 'droplet_ctl/action'

module DropletCtl
  module Actions
    def trigger(action_type, params = {})
      response = API.post_request(
        "#{path}/actions",
        { type: action_type }.merge(params)
      )
      Action.new(response['action']['id'])
    end
  end
end
