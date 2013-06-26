require 'data_mapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/database.sqlite3")

class Music
  include DataMapper::Resource

  property :id,         Serial
  
  property :origin_url, String
  validates_uniqueness_of :origin_url

  property :mp3_url,    String

  property :lyric_url,  String

  property :album_id,   Integer

  property :artist_id,  Integer

  property :created_at, DateTime
  property :updated_at, DateTime
end

class Artist
  include DataMapper::Resource

  property :id,         Serial
  property :origin_url, String
  validates_uniqueness_of :origin_url

  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.auto_upgrade!
