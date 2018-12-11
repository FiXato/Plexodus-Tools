#!/usr/bin/env ruby
# encoding: utf-8
require 'addressable'

module GoogleTakeout
  KNOWN_APIS = {
    gplus_people: {
      documentation: 'https://developers.google.com/+/web/api/rest/latest/people',
      invalid_states: [:missing_person, :lookup_error],
      retryable_states: [:unknown_error, :server_error]
    },
    # contacts: {
    #   documentation: 'https://developers.google.com/contacts/v3/',
    #   invalid_states: [],
    # },
    # people: {
    #   documentation: 'https://developers.google.com/people/api/rest/',
    #   invalid_states: [],
    # },
  }
  class User
    extend ::DataStorage
    class << self
      attr_accessor :users_filepath

      def users_filepath
        @users_filepath ||= File.join('data', 'users')
      end

      def []
        @users ||= load_users_from_file
      end

      def load_users_from_file
        (read_data_file(filepath: users_filepath, format: :yaml, auto_append_extension: :auto) || {})
      end
    end

    attr_reader :data, :user_id, :api_states

    def initialize(user_id: nil)
      @user_id = user_id
      @data = {
        api: KNOWN_APIS.keys.map{|k|[k, nil]}.to_h,
        takeout: {
          circles: {},
          # contacts: {},
          # activities: {},
        },
        circles: {
        },
        file_references: [],
      }
      @api_states = KNOWN_APIS.keys.map{|k|[k, nil]}.to_h
      @errors = []
    end

    def display_name
      from_api[:gplus_people]&.display_name || @data[:takeout][:circles][:displayName]
    end

    def from_api
      @data[:api]
    end

    def has_api_data?(source: nil)
      return from_api.any?{|key, value|!value.to_h.empty?} if source.nil?
      return !from_api[source].to_h.empty?
    rescue StandardError => e
      binding.pry
    end

    #FIXME: rename to something more appropriate
    def valid_api_state?(source:)
      api_state = api_states[source]
      return true if [nil, :success].include?(api_state)
      return true if KNOWN_APIS[source][:retryable_states].include?(api_state)
      return false if KNOWN_APIS[source][:invalid_states].include?(api_state)
      raise "Unknown API State: #{api_states[source]}"
    end

    def api_data_has_errors?(source: nil)
      return from_api.any?{|key, value|value.to_h.has_key?(:error)} if source.nil?
      return from_api[source].to_h.has_key?(:error)
    end

    def set_api_state(source:, state:)
      api_states[source] = state
    end

    def gplus_people_data
      @data[:api][:gplus_people] rescue nil
    end

    def from_takeout
      @data[:takeout]
    end

    def circles
      @data[:circles]
    end

    def add_circle(circle:)
      circle = Circle[circle] if circle.kind_of?(String)
      raise "Unknown circle format: #{circle.class.name}" unless circle.kind_of?(Circle)
      @data[:circles][circle.name] = circle
    end

    def set_data(source:, type:, data:)
      @data[source][type] = data
    end

    def set_api_data(type:, data:)
      set_data(source: :api, type: type, data: data)
    end

    def set_takeout_data(type:, data:)
      # We don't want a duplicate of the API data in the Takeout Circle data.
      data = data.reject{|k,v| [:api_data].include?(k) }
      set_data(source: :takeout, type: type, data: data)
    end

    def file_references
      @data[:file_references]
    end

    def add_error(error_hash)
      @errors << error_hash
    end

    def urls
      gplus_people_data&.urls || []
    end

    def urls_by_site
      urls.group_by do |url|
        uri = Addressable::URI.parse(url&.value||url[:value])
        domain = uri.host.gsub(/^www\./, '')
        #FIXME: use UriUtils and #canonical_host?
        Site.find(domain: domain, path: uri.path)&.name||domain
      end
    end
  end
end