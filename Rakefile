#!/usr/bin/env ruby

require './model'
require './spider'

namespace :spider do
  task :crawl do

    Spider.site('http://www.xiami.com', max_concurrency: 200, max_request: 1000) do |spider|

      spider.keep_links_like(
        /\/artist(\/\d+)./,
        /\/album(\/\d+)./,
        /\/song(\/\d+)./,
        /\/music/,
        /\/song\/tag/,
        /\/collect/,
        /\/song\/showcollect\/id/,
        /\/zone\/index\/id/
      )

      spider.on_links_like(/song\/\d+/) do |url|
        puts url
      end

      spider.on_links_like(/album\/\d+/) do |url|
        puts url
      end

    end


  end

  task :fetch do
    if ARGV[1] && File.exists?(path = File.expand_path("../#{ARGV[1]}", __FILE__))

      urls = open(path) do |f|
        f.readlines.map do |url|
          case url
          when /song\/\d+/
            Song.data_url(url.match(/\d+/)[0])
          when /album\/\d+/
            Album.data_url(url.match(/\d+/)[0])
          end
        end.compact
      end

      Spider.site(urls, max_concurrency: 20, max_request: 100) do |spider|
        spider.on_pages_like(/song/) do |request|
          request.on_success do |response|
            Song.from_json(response.body).save
          end
        end

        spider.on_pages_like(/album/) do |request|
          request.on_success do |response|
            Album.from_json(response.body).save
          end
        end

      end

    end

  end
end
