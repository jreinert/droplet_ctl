require 'droplet_ctl/api'

module DropletCtl
  class APIEndpoint
    class MalformedResponse < RuntimeError; end
    attr_reader :path, :id

    def initialize(id)
      @id = id
      @path = "#{self.class.path}/#{@id}"
    end

    def self.endpoint_name
      path[/.*?(?=s?$)/]
    end

    def self.all(get_query_params = nil)
      response = API.get_request(path, get_query_params)
      response[path]
    end

    def self.where(query, get_query_params = nil)
      result = []
      all(get_query_params).each do |item|
        result << new(item['id']) if match_query(item, query)
      end
      result
    end

    def self.find_by(query, get_query_params = nil)
      item = all(get_query_params).find do |i|
        match_query(i, query)
      end
      return unless item
      new(item['id'])
    end

    def info
      response = API.get_request(path)
      response[self.class.endpoint_name]
    end

    def name
      info['name']
    end

    def destroy
      API.delete_request(path)
    end

    def update(attributes)
      API.put_request(path, attributes)
    end

    def self.match_query(item, query)
      query.all? do |key, value|
        item[key.to_s] == value
      end
    end
  end
end
