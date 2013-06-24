#!/usr/bin/env ruby

require './model'
require './spider'

namespace :spider do
  task :crawl do

    Spider.crawl('http://www.xiami.com') do |url|
      case url
      when /song\/\d+$/
        puts url
        Music.create(origin_url: url, created_at: Time.now)
      end
    end

  end

end
