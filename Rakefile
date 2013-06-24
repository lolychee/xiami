#!/usr/bin/env ruby

require 'anemone'
require './model'

namespace :spider do
  task :crawl do

    Anemone.crawl("http://www.xiami.com/") do |anemone|
      anemone.focus_crawl do |page|
        page.links.each do |url|

          case url.to_s
          when /song\/\d+$/
            Music.create(origin_url: url, created_at: Time.now)
          end

        end
      end
    end

  end

end
