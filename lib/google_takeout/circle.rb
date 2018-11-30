#!/usr/bin/env ruby
# encoding: utf-8
module GoogleTakeout
  class Circle
    attr_reader :name
    # , :members
    def initialize(name:)
      @name = name
      # @members = []
    end

    def self.[](name)
      @circles ||= {}
      @circles[name] ||= self.new(name: name)
    end
  end
end