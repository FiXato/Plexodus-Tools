#!/usr/bin/env ruby
# encoding: utf-8

module ErrorHash
  def to_h
    hash = {
      error: {
        class_name: self.class.name,
        message: (self.message rescue ''),
      }
    }
    hash[:error][:status_code] = self.status_code if self.respond_to?(:status_code)
    hash[:error].merge(super) rescue nil
    return hash
  end
end
