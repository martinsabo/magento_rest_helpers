require 'oauth'
require 'rest_client'
require 'nokogiri'
require 'json'
require 'addressable/uri'

module MagentoRestHelpers
  module ApiClient
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :site, :consumer_key, :consumer_secret, :access_token, :access_token_secret
    end

    def get_data(resource, conditions, response_format: :xml)
      consumer = OAuth::Consumer.new(ApiClient.configuration.consumer_key, ApiClient.configuration.consumer_secret,
                                     {:site => ApiClient.configuration.site})
      access_token = OAuth::AccessToken.new(consumer, ApiClient.configuration.access_token,
                                            ApiClient.configuration.access_token_secret)

      RestClient.add_before_execution_proc do |req, req_params|
        access_token.sign! req
      end

      # restclient/magento had auth issues (401) when get filter params were provided as  :params parameter of get method
      # creating the filter query string aside and passing them as part of url works
      query_string = conditions.nil? ? '' : "?#{magento_query_string(conditions)}"
      url = Addressable::URI.join(ApiClient.configuration.site, resource, query_string).to_s
      response = RestClient.get URI::escape(url), accept: response_format

      if response_format == :xml
        Nokogiri::XML(response, nil, 'UTF-8')
      elsif response_format == :json
        JSON.load(response)
      end
    end

    def magento_query_string(conditions)
      query_params = {}
      unless conditions[:filter].nil?
        conditions[:filter].each_with_index do |condition, index |
          query_params["filter[#{index+1}][attribute]"] = condition[:attr_name]

          raise RuntimeError.new("Unknown magento operator present in filters array.") unless valid_operator(condition[:operator])
          query_params["filter[#{index+1}][#{condition[:operator]}]"] = condition[:value]
        end
      end

      query_params['limit'] = conditions[:limit] unless conditions[:limit].nil?
      query_params['page'] = conditions[:page] unless conditions[:page].nil?
      query_params['order'] = conditions[:order] unless conditions[:order].nil?
      query_params['dir'] = conditions[:dir] unless conditions[:dir].nil?

      query_params.collect{|key, val| "#{key}=#{val}" }.join('&')
    end

    def valid_operator(operator)
      ["neg","in", "nin", "gt", "lt", "from", "to"].include? operator
    end

  end
end