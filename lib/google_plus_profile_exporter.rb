#!/usr/bin/env ruby
# encoding: utf-8

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/plus_v1'
require 'clipboard'
require 'oj'
require 'yaml'
require 'pry'
require 'logger'
require 'pathname'

require_relative 'google_takeout/user.rb'
require_relative 'google_takeout/circle.rb'
require_relative 'error_hash.rb'

class GooglePlusProfileExporter
  DEBUG   = ENV['DEBUG'] || false
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  Plus    = Google::Apis::PlusV1

  attr_reader :users_file,
    :errors_file,
    :authorizer,
    :gplus_client,
    :client_user_id,
    :takeout_directory,
    :takeout_circles_directory,
    :logger,
    :data_directory

  def initialize(
    client_user_id: 'me',
    logger: Logger.new(STDOUT),
    data_directory: Pathname.getwd.join('data'),
    takeout_path: Pathname.getwd.join('Takeout'),
    users_filename: 'processed_users.yaml',
    errors_filename: 'errors.yaml',
    token_store_filename: 'tokens.yaml',
    client_id_filename: 'client_id.json'
  )
    @client_user_id     = client_user_id
    @logger             = logger
    @data_directory     = Pathname.new(File.expand_path(data_directory))
    @takeout_directory  = Pathname.new(File.expand_path(takeout_path))
    @takeout_circles_directory = takeout_directory.join('Google+ Circles')
    @users_file         = data_directory.join(users_filename)
    @errors_file        = data_directory.join(errors_filename)
    @token_store_file     = data_directory.join(token_store_filename)
    @client_id_file     = data_directory.join(client_id_filename)
    setup_client
    logger.debug "Debugging enabled" if DEBUG
  end

  def users
    @users ||= (read_data_file(filepath: users_file, format: :yaml) || {})
  end

  def errors
    @errors ||= {missing_profile: {}, empty_circles: [], lookup: [], other: [], archive: (read_data_file(filepath: errors_file, format: :yaml)||{})}
  end

  def takeout_circles_directory=(path)
    Pathname.new(File.expand_path(path))
  end

  def takeout_circle_files
    @takeout_circle_files ||= Dir.glob(takeout_circles_directory.join('*.json'))
  end

  def add_gplus_people_api_data_to_takeout_circle_files(store_users_after_each_circle: true)
    takeout_circle_files.each do |json_file|
      circle = parse_takeout_circle_file(file: json_file) #TODO: Extract to Circle#parse_takeout_file
      circle[:filepath] = json_file
      process_people_from_circle(circle: circle) #TODO: Extract to Circle#process_people
      store_users if store_users_after_each_circle
    end
  end

  def parse_takeout_circle_file(file:)
    logger.debug "Reading: #{file}"
    Oj.load(File.read(file),{symbol_keys: true})
  end

  def process_people_from_circle(circle:)
    return track_empty_circle(circle: circle) unless circle[:person]

    logger.info "Found circle '#{circle[:name]}' containing #{circle[:person].size} users:"
    circle[:person].each do |person|
      #TODO: move this function to User#set_user_id_from_url or User#initialize?
      user_id = url_to_user_id(person[:profileUrl])
      person[:user_id] = user_id


      #TODO: move this to User
      user = find_or_create_user(user_id: user_id)

      user.set_takeout_data(type: :circles, data: person) unless person.nil?
      user.add_circle(circle: circle[:name]) if circle && circle.has_key?(:name)
      user.file_references << circle[:filepath] unless user.file_references.include?(circle[:filepath])

      api_source = :gplus_people
      if user.has_api_data?(source: api_source)
        logger.info "User with id '#{user_id}' already has added data from Google+ People API."
        #TODO: add staleness checks?
        api_data = user.gplus_people_data
      #TODO: allow forcing a new data lookup
      elsif user.valid_api_state?(source: api_source)
        api_data = query_gplus_people_api_for_user_data(user: user, person: person)
      else
        logger.info "Skipping lookup for user #{user.user_id} due to API state: #{user.api_states[api_source]}"
        next
      end
      user.set_api_data(type: api_source, data: api_data) unless api_data.nil?
    end

    # We don't want the api_data duplicated on the actual User. This can probably be done cleaner, but I'm lazy atm.
    data = circle.clone
    data[:person].each do |person|
      person[:api_data] = users[person[:user_id]].from_api
    rescue StandardError => e
      binding.pry
    end

    logger.info "Saving users with added API info to '#{circle[:filepath]}'"
    save_data_file(filepath: circle[:filepath], data: data, format: :json, json_indent: 2)

    # binding.pry
  end

  def store_users(format: :yaml, filepath: users_file, json_indent: 0)
    logger.info "Processed a total of #{users.keys.size} unique users."
    save_data_file(filepath: filepath, data: users, format: format, json_indent: json_indent)
  end

  def store_errors
    logger.info "Storing a total of #{errors[:empty_circles].size rescue 'N/A'} Empty Circle errors, #{errors[:missing_profile].keys.size rescue 'N/A'} Missing Profiles, #{errors[:lookup].size rescue 'N/A'} Profile Lookup errors, and #{errors[:other].size rescue 'N/A'} Other errors."
    data = errors[:archive]
    data[Time.now.strftime('%Y%m%d-%H%M')] = errors.reject{|k,v|k == :archive}

    save_data_file(filepath: errors_file, data: data, format: :yaml)
  end

  def url_to_user_id(url)
    url.gsub(/^https:\/\/plus\.google\.com\//, '')
  end

  def users_with_api_state(state:, api: :gplus_people)
    users.select{|uid,u|u.api_states[api] == state}
  end

  def users_without_gplus_profiles
    users_with_api_state(state: :missing_person, api: :gplus_people)
  end

  def users_with_gplus_lookup_errors
    users_with_api_state(state: :lookup_error, api: :gplus_people)
  end

protected

  def setup_client
    client_id    = Google::Auth::ClientId.from_file(@client_id_file)
    token_store  = Google::Auth::Stores::FileTokenStore.new(:file => @token_store_file)
    @authorizer   = Google::Auth::UserAuthorizer.new(client_id, scope='https://www.googleapis.com/auth/plus.login', token_store)
    @gplus_client  = Plus::PlusService.new
    @gplus_client.authorization = credentials(client_user_id: client_user_id)
  end

  def credentials(client_user_id:)
    return @credentials if @credentials
    @credentials = authorizer.get_credentials(client_user_id)
    get_authorised(client_user_id: client_user_id) if @credentials.nil?
    return @credentials
  end

  def get_authorised(client_user_id:)
    url = authorizer.get_authorization_url(base_url: OOB_URI )
    puts "URL has been copied to your clipboard" if (Clipboard.copy(url))
    puts "Open #{url} in your browser and enter the resulting code:"
    code = gets.chomp
    @credentials = authorizer.get_and_store_credentials_from_code(user_id: client_user_id, code: code, base_url: OOB_URI)
  end

  def profile_not_found?(user_id)
    errors[:missing_profile].has_key?(user_id) #TODO: use User#api_states instead?
  end

  def track_missing_profile(user: nil, user_id: nil)
    raise ArgumentError.new("Either :user_id or :user keyword need to be specified") if user.nil? && user_id.nil?
    if user_id.nil?
      user_id = user.user_id
    elsif user.nil?
      user = users[user_id]
    end
    errors[:missing_profile][user_id] = user
  end

  def track_lookup_error(user_id:, error_hash:, person:)
    logger.error "Unknown lookup error: #{error_hash[:error][:class_name]}('#{error_hash[:error][:message]}')"
    errors[:lookup] << {
      user_id: user_id,
      profile_url: person[:profileUrl],
    }.merge(error_hash)
  end

  def track_empty_circle(circle:)
    logger.debug "Circle #{circle[:name]} appears to have no members: #{circle.inspect}"
    errors[:empty_circles] << GoogleTakeout::Circle[circle]
  end

  def find_or_create_user(user_id:)
    user = users[user_id]
    return user if user.kind_of?(GoogleTakeout::User)
    user = GoogleTakeout::User.new(user_id: user_id)
    users[user_id] = user
    return user
  end

  def read_data_file(filepath:, format: :json)
    return nil unless File.exist?(filepath)
    logger.info "Reading data from #{filepath}"
    if format == :json
      Oj.load(File.read(filepath), {symbol_keys: true, mode: :custom})
    elsif format == :yaml
      YAML.load_file(filepath)
    else
      raise "Unsupported Format: #{format}"
    end
  end

  def save_data_file(filepath:, data:, format: :json, json_indent: 0)
    logger.info "Saving data to #{filepath} in #{format.to_s} format"

    if format == :json
      string = Oj.dump(data, {mode: :custom, indent: json_indent.to_i})
    elsif format == :yaml
      string = data.to_yaml
    else
      raise "Unsupported data format: #{format}"
    end
    # TODO: support backing up data file.
    File.open(filepath, 'w+') { |f| f.write(string)}
  end

  def query_gplus_people_api_for_user_data(user:, person:)
    api = :gplus_people
    logger.debug "Looking up user with id '#{user.user_id}."
    api_data = @gplus_client.get_person(user.user_id)

    user.set_api_state(source: api, state: :success)
    return api_data
  rescue Google::Apis::ServerError, Google::Apis::ClientError => e
    e.extend ErrorHash
    error_hash = e.to_h
    error_hash[:source] = api

    if e.message == 'notFound: Not Found'
      logger.info "Google+ People API: Could not find user with id '#{user.user_id}' ('#{person[:displayName]}') with profile URL: #{person[:profileUrl]}"
      track_missing_profile(user_id: user.user_id)
      error_hash[:type] = user.set_api_state(source: api, state: :missing_person)
    elsif e.message == 'Server error'
      binding.pry if DEBUG
      track_lookup_error(user_id: user.user_id, error_hash: error_hash, person: person)
      error_hash[:type] = user.set_api_state(source: api, state: :server_error)
    else
      binding.pry if DEBUG
      track_lookup_error(user_id: user.user_id, error_hash: error_hash, person: person)
      error_hash[:type] = user.set_api_state(source: api, state: :lookup_error)
    end
    user.add_error(error_hash)
    return nil
  rescue StandardError => e
    e.extend ErrorHash
    error_hash = e.to_h
    error_hash[:source] = api
    error_hash[:type] = user.set_api_state(source: api, state: :unknown_error)
    user.add_error(error_hash)
    binding.pry if DEBUG
    return nil
  end
end