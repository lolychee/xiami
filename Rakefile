#!/usr/bin/env ruby

require 'typhoeus'
require './model'

namespace :spider do
  task :crawl do

=begin
    Spider.crawl('http://www.xiami.com') do |url|
      case url
      when /song\/\d+$/
        puts url
        Music.create(origin_url: url, created_at: Time.now)
      end
    end
=end
    hydra = Typhoeus::Hydra.hydra

    on_success = Proc.new do |response|
      xml = Nokogiri::XML(response.body)
      id        = xml.at_css('song_id').content
      artist_id = xml.at_css('artist_id').content
      album_id  = xml.at_css('album_id').content
      lyric_url = xml.at_css('lyric').content
      mp3_url   = xml.at_css('location').content


      row_num = mp3_url.slice!(0).to_i
      col_num, long_num = mp3_url.length.divmod row_num

      matrix = []
      row_num.times do |i|
        matrix[i] =  if i < long_num
          mp3_url.slice!(0..col_num)
        else
          mp3_url.slice!(0...col_num)
        end
      end

      mp3_url.clear

      0.upto(col_num) do |i|
        row_num.times do |j|
          mp3_url += matrix[j][i].to_s
        end
      end

      mp3_url = URI.unescape(mp3_url).gsub('^', '0')



      m = Music.create(
        id: id,
        artist_id:  artist_id, 
        album_id:   album_id,
        mp3_url:    mp3_url,
        lyric_url:  lyric_url
      )

      puts id

    end

    Thread.start do
      (1000000..9999999).each do |i|
        Thread.pass while hydra.queued_requests.size > 1000

        url = "http://www.xiami.com/song/playlist/id/#{i}/object_name/default/object_id/0"

        request = Typhoeus::Request.new(url)

        request.on_success &on_success

        hydra.queue request
      end
    end

    sleep(2)
    hydra.run

  end
end
