#!/usr/bin/env ruby

require './model'
require './spider'

namespace :spider do
  task :crawl do

    Spider.site('http://www.xiami.com') do |url, links|
      links.each do |url|
        case url
        when /song\/\d+$/
          puts url
          Music.create(origin_url: url)
        end
      end
    end

  end

end
