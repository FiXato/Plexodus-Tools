#!/usr/bin/env ruby
# encoding: utf-8
require 'oj'
require 'yaml'
require 'addressable'
require 'easy_logging'
require_relative 'data_storage/data_storage'

class Site
  include ::EasyLogging
  extend ::DataStorage

  @@known_sites = {}

  attr_reader :name, :domains, :profile_template, :homepage, :api_documentation, :path, :defunct, :type
  def initialize(name:, homepage:, domains: [], profile_template: nil, api_documentation: nil, path: nil, defunct: false, type: :undefined)
    raise ArgumentError.new('domains needs to be an array') unless domains.kind_of?(Array)

    @name = name
    @homepage = homepage
    @domains = domains.map{|domain| domain.kind_of?(Regexp) ? domain : domain.downcase.gsub(/^www\./, '')}
    self.profile_template = profile_template if profile_template#FIXME: should support multiple templates
    @api_documentation = api_documentation
    raise ArgumentError.new(':path needs be an instance of nil, String or Regexp') unless path.nil? || path.kind_of?(String) || path.kind_of?(Regexp)
    @path = path
    @defunct = defunct
    @type = type
    @@known_sites[name] = self
  end

  def profile_template=(template)
    template = Addressable::Template.new(template) if template.kind_of?(String)
    raise ArgumentError.new('profile_template needs to be either a String or an Addressable::Template') unless template.kind_of?(Addressable::Template)
    @profile_template = template
  end

  def exact_match_domains
    @exact_match_domains ||= domains.select{|domain|domain.kind_of?(String)}
  end

  def partial_match_domains
    @partial_match_domains ||= domains.select{|domain|domain.kind_of?(Regexp)}
  end

  def self.known_sites
    @@known_sites
  end

  def self.[](key=nil)
    return @@known_sites if key.nil?
    @@known_sites[key]
  end

  def self.find(domain:, path: nil)
    known_sites.values.find do |site|
      next false unless domain_match = site.exact_match_domains.include?(domain.downcase)||site.partial_match_domains.any?{|re| domain.downcase.match(re)}
      next domain_match if site.path.nil?
      next site.path.kind_of?(String) ? site.path == path : site.path.match(path)
    end
  end

  def self.store_known_sites(filepath:, format: :yaml, json_indent: 0, auto_append_extension: :auto)
    save_data_file(filepath: filepath, data: @@known_sites, format: format, json_indent: json_indent, auto_append_extension: auto_append_extension)
  end

  def self.restore_known_sites(filepath:, format: :yaml, auto_append_extension: :auto)
    @@known_sites = read_data_file(filepath: filepath, format: format, auto_append_extension: auto_append_extension)||{}
  end
end
