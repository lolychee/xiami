#!/usr/bin/env ruby

require 'anemone'
require './model'

module Anemone
  class Page
    def to_hash
      {'url' => @url.to_s,
       'headers' => Marshal.dump(@headers),
       'data' => Marshal.dump(@data),
       'links' => links.map(&:to_s), 
       'code' => @code,
       'visited' => @visited,
       'depth' => @depth,
       'referer' => @referer.to_s,
       'redirect_to' => @redirect_to.to_s,
       'response_time' => @response_time,
       'fetched' => @fetched}
    end

    def self.from_hash(hash)
      page = self.new(URI(hash['url']))
      {'@headers' => Marshal.load(hash['headers']),
       '@body' => hash['body'],
       '@links' => hash['links'].map { |link| URI(link) },
       '@code' => hash['code'].to_i,
       '@visited' => hash['visited'],
       '@depth' => hash['depth'].to_i,
       '@referer' => hash['referer'],
       '@redirect_to' => (!!hash['redirect_to'] && !hash['redirect_to'].empty?) ? URI(hash['redirect_to']) : nil,
       '@response_time' => hash['response_time'].to_i,
       '@fetched' => hash['fetched']
      }.each do |var, value|
        page.instance_variable_set(var, value)
      end
      page
    end
  end
end


namespace :spider do
  task :crawl do

    Anemone.crawl("http://www.xiami.com/") do |anemone|
      anemone.storage = Anemone::Storage.SQLite3

      # anemone.focus_crawl do |page|
      # end

      anemone.on_every_page do |page|
        page.links.each do |url|
          case url.to_s
          when /song\/\d+/
            Music.create(origin_url: page.url, created_at: Time.now)
            puts url
          end
        end
      end

    end

  end
end
