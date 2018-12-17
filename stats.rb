#!/usr/bin/env ruby
# encoding: utf-8
#
# usage example: DEBUG=true bundle exec ruby stats.rb --takeout-path "/path/to/extracted/takeout/archive/Takeout/" --checksums-archive-file data/files_by_checksum_and_filesize-`date "+%Y%m%d"`
require_relative File.join('lib', 'cli_toolkit', 'cli_toolkit.rb')
extend CliToolkit::CliOptions

require 'easy_logging'
log_path = (cli_option('--log-file') || nil)
if log_path
  FileUtils.mkdir_p(File.dirname(log_path)) unless File.exist?(File.dirname(log_path))
  EasyLogging.log_destination = log_path
end
EasyLogging.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::Warn
include EasyLogging
logger.info "Log level: #{EasyLogging.level}"

require 'pathname'
require 'pry'
require 'yaml'
require_relative 'lib/data_storage/data_storage.rb'
include DataStorage

class FileDetails
  RE_COUNTER = /\((\d+)\)$/
  require 'filesize'
  require 'mimemagic'
  require 'magic'
  require 'digest'
  attr_reader :size, :human_size, :mime_type, :path, :extensions, :mime_by_path
  def initialize(filepath)
    @path = filepath
    @size = File.size(filepath)
    @human_size = Filesize.from(@size.to_s).pretty
    @basename = File.basename(filepath)
    @mime_by_path = MimeMagic.by_path(path)
    @extensions = basename.split('.')[1..-1]
  end

  def extensions
    return @extensions unless @extensions.empty?
    @extensions = basename.split('.')[1..-1] #FIXME: Because I don't feel like re-generating my local dump
  end
  
  def basename(include_counter: true)
    return include_counter ? @basename : @basename.gsub(RE_COUNTER, '')
  end

  def expanded_path(include_counter: true)
    @expanded_path ||= File.expand_path(path)
    return include_counter ? @expanded_path : @expanded_path.gsub(RE_COUNTER, '')
  end
  
  def full_path(include_counter: true)
    expanded_path(include_counter: include_counter)
  end
  
  def complete_extension(include_counter: true)
    extension(amount: 0, include_counter: include_counter)
  end
  
  def counter
    extension(include_counter: true).match(RE_COUNTER)&.values_at(1)
  end
  
  def extension(amount: 1, include_counter: false)
    if amount == 0
      ext = extensions.join('.')
    else
      ext = extensions.reverse[0,amount].join('.')
    end
    return include_counter ? ext : ext.gsub(RE_COUNTER, '')
  end
  
  def human_size
    @human_size ||= Filesize.from(self.size.to_s).pretty
  end

  def magic
    return @magic ||= File.magic(path)
  end

  def mime_by_magic
    return @mime_by_magic ||= File.mime(path)
  end

  def type_by_magic
    return @type_by_magic ||= File.type(path)
  end
  
  def mime
    [mime_by_path.to_s, type_by_magic].uniq.join(' detected as ')
  end
  
  def md5
    @md5 ||= Digest::MD5.hexdigest(File.read(path))
    # logger.debug "MD5: #{@md5}, #{path}"
    return @md5
  end
end

takeout_dir = Pathname.new(cli_option('--takeout-path'))
all_files = Dir.glob(takeout_dir.join('**','*'))
detailed_files = all_files.reject{|f|File.directory?(f)}.map{|f| FileDetails.new(f)}
detailed_files_by_extension = detailed_files.group_by(&:extension)

detailed_files_by_filename = detailed_files.group_by{|fd| fd.basename(include_counter: false).split('.').first}


# puts "Found #{detailed_files.size} files, and #{detailed_files_by_extension.keys.size} extensions (#{detailed_files_by_extension.keys.join(', ')}):"
# detailed_files_by_extension.each do |ext, fds|
#   puts "== #{ext}"
#   fds[0..10].each do |fd|
#     puts "#{fd.human_size}: #{fd.full_path} (#{fd.mime})"
#   end
# end

files_by_checksum_and_filesize_data_file = (cli_option('--checksums-archive-file')||'data/files_by_checksum_and_filesize')
detailed_files_by_checksum_and_filesize = read_data_file(filepath: files_by_checksum_and_filesize_data_file, format: 'yaml')
if detailed_files_by_checksum_and_filesize.nil? || detailed_files_by_checksum_and_filesize.empty?
  file_counter = 1
  total_file_count = detailed_files.size
  detailed_files_by_checksum_and_filesize = detailed_files.group_by do |fd|
    puts "Calculating md5 for file #{fd.path} [#{file_counter}/#{total_file_count}]"
    file_counter += 1
    [fd.size,fd.md5].join('+')
  end
  save_data_file(filepath: files_by_checksum_and_filesize_data_file, data: detailed_files_by_checksum_and_filesize, format: :yaml)
end

class UniqueFileEntry
  attr_reader :md5, :file_details_entries
  
  def initialize(md5:, file_details_entries: [])
    @md5 = md5
    file_details_entries = [file_details_entries] if file_details_entries.kind_of?(FileDetails)
    raise ArgumentError.new("file_details_entries: needs to be an (array of) FileDetails item(s)") if file_details_entries.any?{|fd|!fd.kind_of?(FileDetails)}
    @file_details_entries = file_details_entries
  end
  
  def filesize
    file_details_entries.first.size
  end
  
  def human_filesize
    Filesize.from(filesize.to_s).pretty
  end
  
  def files
    file_details_entries.map{|fd| fd.expanded_path}
  end
  
  def file_count
    file_details_entries.size
  end
  
  def total_size
    file_count * filesize
  end

  def human_total_size
    Filesize.from(total_size.to_s).pretty
  end
  
  def total_size_from_file_details
    file_details_entries.inject(0){|total, fd| total + fd.size}
  end
  
  def total_wasted_space
    total_size - filesize
  end
  
  def human_total_wasted_space
    Filesize.from(total_wasted_space.to_s).pretty
  end
  
  def to_s
    formatted(human: true, files_format: :oneline)
  end
  
  def formatted(human: true, files_format: :list)
    if files_format == :list
      list = files.map{|f|" - #{f}"}.join("\n")
    elsif files_format == :oneline
      list = files.join(', ')
    elsif files_format == :hidden
      list = nil
    else
      files
    end
    "#{md5}+#{filesize} (#{file_details_entries.first.basename}): #{file_count} files @ #{human ? human_filesize : filesize} = #{human ? human_total_size : total_size} (#{human ? human_total_wasted_space : total_wasted_space} wasted):#{list&.index("\n") ? "\n#{list}" : list}"
  end
end

def report(unique_file_entries:, files_format: :formatted, count: 5, subheader: '', sort_orders: {file_count: 'most amount of duplicates', total_size: 'largest total size', total_wasted_space: 'largest total wasted space'})
  str = "The top #{count} unique file details entries#{subheader}, ordered by:\n\n"

  sort_orders.each do |sort_order, description|
    str += " - #{description}:\n"
    str += unique_file_entries.sort_by{|ufe| ufe.send(sort_order)}.reverse[0,count].map{|ufe| '   - ' + ufe.formatted(files_format: files_format)}.join("\n")
    str += "\n\n"
  end

  total_used_space = unique_file_entries.inject(0){|total, ufe| total + ufe.total_size}
  total_wasted_space = unique_file_entries.inject(0){|total, ufe| total + ufe.total_wasted_space}
  total_actually_required_space = unique_file_entries.inject(0){|total, ufe| total + ufe.filesize}

  str += "Total used space#{subheader}: #{Filesize.from(total_used_space.to_s).pretty}\n"
  str += "Total actually required space#{subheader}: #{Filesize.from(total_actually_required_space.to_s).pretty}\n"
  str += "Total wasted space#{subheader}: #{Filesize.from(total_wasted_space.to_s).pretty}\n"

  return str
end

unique_file_entries = detailed_files_by_checksum_and_filesize.map do |checksum, fds|
  UniqueFileEntry.new(md5: fds.first.md5, file_details_entries: fds)
end
unique_file_entries_by_extension = unique_file_entries.group_by{|ufe|ufe.file_details_entries.first.extension}

puts "Found #{unique_file_entries.size} unique files with identical checksum+filesize combinations:"

puts report(unique_file_entries: unique_file_entries, files_format: :hidden)

unique_file_entries_by_extension.each do |extension, ufes|
  puts
  puts "## #{extension}"
  puts report(unique_file_entries: ufes, files_format: :hidden, subheader: " for files with file extension #{extension}",sort_orders: {total_wasted_space: 'largest total wasted space'})
end

# puts "Found #{detailed_files_by_filename.keys.size} files with unique names:"
# detailed_files_by_filename.each do |filename, fds|
#   puts "== #{filename}"
#   fds[0..10].each do |fd|
#     puts "#{fd.human_size}: #{fd.full_path} (#{fd.mime})"
#   end
# end

binding.pry
