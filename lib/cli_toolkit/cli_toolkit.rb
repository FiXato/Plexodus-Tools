#!/usr/bin/env ruby
# encoding: utf-8

module CliToolkit
  module CliOptions
    def cli_flag(key)
      return ARGV.include?(key)
    end

    def cli_option(key)
      return nil unless index = ARGV.index(key)
      value = ARGV[index + 1]
      raise "You need to specify a value for #{key}" unless value
      return value
    end
  end

  module CliHash
    def set_from_argv(key, argument)
      if (value = CliParser.cli_option(argument))
        self[key] = value
      end
    end
  end

  class CliParser
    extend CliOptions
  end
end