#!/usr/bin/env ruby

require './model'
require './spider'

namespace :spider do
  task :crawl do

    Spider.site('http://www.xiami.com') do |url, links|
      links.keep_if do |url|
        [
          /^\/artist(\/\d+)./,
          /^\/album(\/\d+)./,
          /^\/song(\/\d+)./,
          /^\/music/,
          /^\/song\/tag/,
          /^\/collect/,
          /^\/song\/showcollect\/id/,
          /^\/zone\/index\/id/
        ].inject(false) do |memo, regular|
          memo = true if url[20..-1] =~ regular
          memo
        end
      end

      links.each do |url|
        case url
        when /song\/\d+/
          puts url
          Music.create(origin_url: url)
        end
      end
    end

  end

end
