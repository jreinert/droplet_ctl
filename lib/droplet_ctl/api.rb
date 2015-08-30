require 'net/http'
require 'json'

module DropletCtl
  module API
    TOKEN = ENV['DIGITAL_OCEAN_API_TOKEN']

    API_ROOT = URI('https://api.digitalocean.com/')
    API_VERSION = 'v2'

    class << self
      def get_request(endpoint, params = nil)
        handle_request(Net::HTTP::Get, endpoint, params)
      end

      def delete_request(endpoint)
        handle_request(Net::HTTP::Delete, endpoint)
      end

      def put_request(endpoint, params = nil)
        handle_request(Net::HTTP::Put, endpoint, params)
      end

      def post_request(endpoint, params = nil)
        handle_request(Net::HTTP::Post, endpoint, params)
      end

      private

      def handle_request(request_class, endpoint, params = nil)
        path = path_for(endpoint, request_class, params)
        request = request_class.new(path.to_s)
        if params && request_class != Net::HTTP::Get
          request.body = params.to_json
          request.content_type = 'application/json'
        end
        response = api_request(request)
        unless response.is_a?(Net::HTTPSuccess)
          fail Error.new("#{request_class} request to #{endpoint} failed", request, response)
        end

        JSON.parse(response.body)
      end

      def path_for(endpoint, request_class, params)
        uri = URI("/#{API_VERSION}/#{endpoint}")
        return uri if params.nil? || request_class != Net::HTTP::Get
        uri.query = URI.encode_www_form(params)
        uri
      end

      def form_encode_params(params)
        CGI.build_form do |form|
          params.each { |key, value| form.add(key.to_s, value.to_s) }
        end
      end

      def api_request(request)
        sleep 1 # be polite
        request['Authorization'] = "Bearer #{TOKEN}"
        Net::HTTP.start(
          API_ROOT.host, API_ROOT.port, use_ssl: API_ROOT.scheme == 'https'
        ) do |client|
          client.request(request)
        end
      end
    end
  end

  class API::Error < RuntimeError
    def initialize(message, request, response)
      uri = URI(API_ROOT.to_s)
      uri.path = request.uri.path
      uri.query = request.uri.query
      super(
        "#{message}\n" \
        "\tRequest URI: #{uri}\n" \
        "\tRequest: #{request.inspect}\n" \
        "\tResponse: #{response.inspect}\n" \
      )
    end
  end
end
