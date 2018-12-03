#!/usr/bin/env ruby
# encoding: utf-8
require 'oj'
require 'yaml'
require 'addressable'

class Site
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

  #FIXME: modularise data storage/retrieval
  def self.store_known_sites(filepath:, format: :yaml, json_indent: 0)
    #FIXME: use Logger instead
    puts "Saving data to #{filepath} in #{format.to_s} format"

    if format == :json
      string = Oj.dump(@@known_sites, {mode: :custom, indent: json_indent.to_i})
    elsif format == :yaml
      string = @@known_sites.to_yaml
    else
      raise "Unsupported data format: #{format}"
    end
    # TODO: support backing up data file.
    File.open(filepath, 'w+') { |f| f.write(string)}
  end

  def self.restore_known_sites(filepath:, format: :yaml)
    return nil unless File.exist?(filepath)
    #FIXME: use Logger instead
    puts "Reading data from #{filepath}"
    if format == :json
      @@known_sites = Oj.load(File.read(filepath), {symbol_keys: true, mode: :custom})
    elsif format == :yaml
      @@known_sites = YAML.load_file(filepath)
    else
      raise "Unsupported Format: #{format}"
    end
  end
end
