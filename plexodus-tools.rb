#!/usr/bin/env ruby
# encoding: utf-8
require 'fileutils'
require_relative File.join('lib', 'cli_toolkit', 'cli_toolkit.rb')
extend CliToolkit::CliOptions

require 'easy_logging'
log_path = (cli_option('--log-file') || 'logs/plexodus-tools.log')
FileUtils.mkdir_p(File.dirname(log_path)) unless File.exist?(File.dirname(log_path))
EasyLogging.log_destination = log_path
EasyLogging.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::Warn
include EasyLogging
logger.info "Log level: #{EasyLogging.level}"

require_relative File.join('lib', 'google_plus_profile_exporter.rb')

gppe_options = {}
gppe_options.extend CliToolkit::CliHash
gppe_options.set_from_argv(:takeout_path, '--takeout-path')
gppe_options.set_from_argv(:data_directory, '--data-directory')
gppe_options.set_from_argv(:client_user_id, '--client-user-id')
gppe_options.set_from_argv(:users_filename, '--users-filename') # relative to data directory
gppe_options.set_from_argv(:errors_filename, '--errors-filename') # relative to data directory
gppe_options.set_from_argv(:client_id_filename, '--client-id-filename') # relative to data directory
gppe_options.set_from_argv(:token_store_filename, '--token-store-filename') # relative to data directory

def section_header(header_text)
  output = ['']
  output << section_separator
  output << header_text
  output << section_separator('-')
  output.join("\n")
end

def section_separator(str = '=')
  str*80
end

def indent(indent_level: 1, content: nil)
  output = ' ' * indent_level
  if content.kind_of?(Array)
    output = content.map{|str| "#{output}#{str}" }
  else
    output += content.to_s
  end
  output
end

Site.restore_known_sites(filepath: File.join('data', 'sites.yaml'), format: :yaml)

gppe = GooglePlusProfileExporter.new(**gppe_options)

if (profile_url = cli_option('--lookup-profile'))
  user_id = gppe.url_to_user_id(profile_url)
  pp gppe.lookup_user(user_id: user_id).to_h
end

if cli_flag('--parse-takeout-circles')
  puts section_header('Parsing Takeout Circles:')
  gppe.add_gplus_people_api_data_to_takeout_circle_files
  puts section_separator
end

if cli_flag('--users-with-missing-profiles')
  puts section_header('Users with Missing Profiles:')
  if gppe.users.empty?
    puts "No users found. Maybe run --parse-takeout-circles first?"
  else
    users_without_profiles = gppe.users_without_gplus_profiles
    puts "Found #{users_without_profiles.keys.size} users without GPlus profiles:"
    puts users_without_profiles.map{|uid,u|u.display_name}.sort_by{|uname|uname.downcase}
  end
  puts section_separator
end

if cli_flag('--users-with-lookup-errors')
  puts section_header('Users with Lookup Errors:')
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
  puts section_separator
end

show_urls = cli_flag('--urls-by-site')
if show_urls || cli_flag('--site-stats')
  puts section_header('URLs by Platform results:')

  url_items_grouped_by_site = gppe.url_items_grouped_by_site(sort_by: :unique_canonical_urls_count, supported_types: [:undefined, :profile, :blog, :social_media_network])
  puts "Found #{url_items_grouped_by_site.keys.size} sites: "
  url_items_grouped_by_site.each do |site_name, url_items|
    grouped_by_canonical_urls = GooglePlusProfileExporter.group_url_items_by_canonical_url(url_items: url_items, sort_by: :reverse_item_count)
    total_urls = url_items.size
    total_unique_urls = grouped_by_canonical_urls.keys.size
    puts indent(indent_level: 1, content: "— #{site_name} (#{url_items.size} items#{" / #{total_unique_urls} unique items" if total_urls != total_unique_urls})#{':' if show_urls}")

    if show_urls
      grouped_by_canonical_urls.each do |canonical_url, canonical_url_items|
        puts indent(indent_level: 2, content: "– #{canonical_url}:") if canonical_url_items.size > 1

        canonical_url_items.each do |url_item|
          text = url_item.user.display_name
          text += ", #{url_item.label}" unless url_item.label.downcase == site_name.downcase || url_item.label.downcase == url_item.user.display_name.downcase
          text += ": #{url_item.value}"
          puts indent(indent_level: 2 + (canonical_url_items.size > 1 ? 1 : 0), content: text)
        end
      end
    end
  end
  puts section_separator
end

#gppe.store_users # save the default (yaml format)
gppe.store_users(format: :json, filepath: gppe.users_file.to_s.gsub(/\.yaml$/,'.json'), json_indent: 2) #Save another copy as json
gppe.store_errors


binding.pry
