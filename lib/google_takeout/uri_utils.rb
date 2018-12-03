#!/usr/bin/env ruby
# encoding: utf-8
require 'addressable'

module GoogleTakeout
  module UriUtils
    attr_reader :uri

    def uri=(url)
      @uri = Addressable::URI.parse(url)
    end

    def canonical_host
      @canonical_host ||= uri.host.gsub(/^www\./, '')
    end

    def canonical_url
      @canonical_url ||= uri.merge(host: uri.host.gsub(/^www\./, '')).to_s
    end
  end
end
