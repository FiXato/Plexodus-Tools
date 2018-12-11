#!/usr/bin/env ruby
# encoding: utf-8
module DataStorage
  include EasyLogging

  def read_data_file(filepath:, format: :json, auto_append_extension: :auto)
    filepath_with_extension = filepath_with_format_extension(filepath: filepath, format: format, auto_append_extension: auto_append_extension)
    unless File.exist?(filepath_with_extension)
      logger.warn "#{format} data file '#{filepath_with_extension}' does not exist."
      return nil
    end

    logger.info "Reading data from #{filepath_with_extension}"

    if format == :json
      return Oj.load(File.read(filepath_with_extension), {symbol_keys: true, mode: :custom})
    elsif format == :yaml
      return YAML.load_file(filepath_with_extension)
    else
      raise "Unsupported Format: #{format}"
    end
  end

  def save_data_file(filepath:, data:, format: :json, json_indent: 0, auto_append_extension: :auto)
    filepath_with_extension = filepath_with_format_extension(filepath: filepath, format: format, auto_append_extension: auto_append_extension)
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

  protected
  def filepath_with_format_extension(filepath:, format:, auto_append_extension: :auto)
    filepath_with_extension = filepath.to_s
    filepath_with_extension.gsub!(/\.#{format.to_s}$/,'') if auto_append_extension == :auto
    filepath_with_extension += ".#{format.to_s}" if auto_append_extension
  end
end