#!/usr/bin/env ruby

require './model'
require './spider'

namespace :spider do
  task :crawl do

    Spider.site('http://www.xiami.com', max_concurrency: 1000, max_request: 2000) do |spider|
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
        begin
          url = Song.data_url(url.match(/\d+/)[0])
          response = Typhoeus.get(url, followlocation: true)
          Song.from_json(response.body).save if response.success?
        rescue
          puts "E #{url}"
        end
      end

      spider.on_links_like(/album\/\d+/) do |url|
        begin
          url = Album.data_url(url.match(/\d+/)[0])
          response = Typhoeus.get(url, followlocation: true)
          Album.from_json(response.body).save if response.success?
        rescue
          puts "E #{url}"
        end
      end

      spider.on_pages_like(/.*/) do |request|
        request.on_success do |response|
          puts "S #{request.url}"
        end
        request.on_failure do |response|
          puts "F #{request.url}"
        end
      end

      spider.on_links_like(/.*/) do |url|
        puts "Q #{url}"
      end
    end
  end

end
