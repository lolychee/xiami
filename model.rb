require 'data_mapper'
require 'json'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/database.sqlite3")

class Music
  include DataMapper::Resource

  property :id,         Serial
  validates_uniqueness_of :id

  property :mp3_url,    String

  property :origin_url,  String
  validates_uniqueness_of :origin_url

  property :lyric_url,  String

  property :album_id,   Integer

  property :artist_id,  Integer

  property :created_at, DateTime
  property :updated_at, DateTime

end

class Song
  include DataMapper::Resource

  property :id,               Serial
  validates_uniqueness_of :id

  belongs_to :album
  property :artist_id,        Integer

  property :name,             String
  property :album_name,       String
  property :artist_name,      String
  property :singer_names,     String

  property :song_url,         Text
  property :lyric_url,        Text
  property :album_cover_url,  Text

  property :vote_up_count,    Integer

  property :created_at,       DateTime
  property :updated_at,       DateTime

  def self.data_url(id)
    "http://www.xiami.com/app/iphone/song/id/#{id}"
  end

  def self.from_json(s)
    new.from_json(s)
  end

  def from_json(s)
    data = s.is_a?(Hash) ? s : JSON.parse(s)

    self.id             = data['song_id']
    self.album_id       = data['album_id']
    self.artist_id      = data['artist_id']

    self.name           = data['name']
    self.album_name     = data['title']
    self.artist_name    = data['artist_name']
    self.singer_names   = data['singers']

    self.song_url       = data['location']
    self.lyric_url      = data['lyric']
    self.album_cover_url= data['album_logo']

    self.vote_up_count  = data['recommends']

    self
  end

end

class Album
  include DataMapper::Resource

  property :id,             Serial
  validates_uniqueness_of :id
  property :name,           String
  property :description,    String

  property :cover_url,      Text

  property :created_at,     DateTime
  property :updated_at,     DateTime

  has n, :songs

  def self.data_url(id)
    "http://www.xiami.com/app/iphone/album/id/#{id}"
  end

  def self.from_json(s)
    new.from_json(s)
  end

  def from_json(s)
    data = s.is_a?(Hash) ? s : JSON.parse(s)['album']
    self.id           = data['album_id']
    self.name         = data['title']
    self.cover_url    = data['album_logo']
    self.description  = data['description']

    self.songs        = data['songs'].map {|id, song| Song.get(id.to_i) or Song.from_json(song).tap(&:save) }

    self
  end

end

class Artist
  include DataMapper::Resource

  property :id,             Serial
  validates_uniqueness_of :id

  property :name,           String
  property :description,    String

  property :picture_url,    Text

  property :album_count,    Integer

  property :created_at,     DateTime
  property :updated_at,     DateTime

  def self.data_url(id)
    "http://www.xiami.com/app/iphone/artist/id/#{id}"
  end


end

DataMapper.auto_upgrade!
