#!/usr/bin/env ruby
# encoding: utf-8
require_relative File.join('lib', 'google_plus_profile_exporter.rb')
require_relative File.join('lib', 'cli_toolkit', 'cli_toolkit.rb')

extend CliToolkit::CliOptions

gppe_options = {}
gppe_options.extend CliToolkit::CliHash
gppe_options.set_from_argv(:takeout_path, '--takeout-path')
gppe_options.set_from_argv(:data_directory, '--data-directory')
gppe_options.set_from_argv(:client_user_id, '--client-user-id')
gppe_options.set_from_argv(:users_filename, '--users-filename') # relative to data directory
gppe_options.set_from_argv(:errors_filename, '--errors-filename') # relative to data directory
gppe_options.set_from_argv(:client_id_filename, '--client-id-filename') # relative to data directory
gppe_options.set_from_argv(:token_store_filename, '--token-store-filename') # relative to data directory


gppe = GooglePlusProfileExporter.new(**gppe_options)

if (profile_url = cli_option('--lookup-profile'))
  user_id = gppe.url_to_user_id(profile_url)
  pp gppe.lookup_user(user_id: user_id).to_h
end

if cli_flag('--parse-takeout-circles')
  gppe.add_gplus_people_api_data_to_takeout_circle_files
end

if cli_flag('--users-with-missing-profiles')
  if gppe.users.empty?
    puts "No users found. Maybe run --parse-takeout-circles first?"
  else
    users_without_profiles = gppe.users_without_gplus_profiles
    puts "Found #{users_without_profiles.keys.size} users without GPlus profiles:"
    puts users_without_profiles.map{|uid,u|u.display_name}.sort_by{|uname|uname.downcase}
  end
end

if cli_flag('--users-with-lookup-errors')
  if gppe.users.empty?
    puts "No users found. Maybe run --parse-takeout-circles first?"
  else
    users_with_lookup_errors = gppe.users_with_gplus_lookup_errors
    if users_with_lookup_errors.empty?
      puts "No lookup errors detected"
    else
      puts "Found #{users_with_lookup_errors.keys.size} users with lookup errors:"
      puts users_with_lookup_errors.map{|uid,u|u.display_name}.sort_by{|uname|uname.downcase}
    end
  end
end

#gppe.store_users # save the default (yaml format)
gppe.store_users(format: :json, filepath: gppe.users_file.to_s.gsub(/\.yaml$/,'.json'), json_indent: 2) #Save another copy as json
gppe.store_errors


binding.pry
