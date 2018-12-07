#!/usr/bin/env ruby
# encoding: utf-8
module DataStorage
  include EasyLogging

  def read_data_file(filepath:, format: :json, auto_append_extension: false)
    filepath_with_extension = auto_append_extension ? filepath + ".#{format.to_s}" : filepath
    return nil unless File.exist?(filepath_with_extension)
    logger.info "Reading data from #{filepath_with_extension}"
    if format == :json
      Oj.load(File.read(filepath_with_extension), {symbol_keys: true, mode: :custom})
    elsif format == :yaml
      YAML.load_file(filepath_with_extension)
    else
      raise "Unsupported Format: #{format}"
    end
  end

  def save_data_file(filepath:, data:, format: :json, json_indent: 0, auto_append_extension: false)
    filepath_with_extension = auto_append_extension ? filepath + ".#{format.to_s}" : filepath
    logger.info "Saving data to #{filepath_with_extension} in #{format.to_s} format"

    if format == :json
      string = Oj.dump(data, {mode: :custom, indent: json_indent.to_i})
    elsif format == :yaml
      string = data.to_yaml
    else
      raise "Unsupported data format: #{format}"
    end
    # TODO: support backing up data file.
    File.open(filepath_with_extension, 'w+') { |f| f.write(string)}
  end
end