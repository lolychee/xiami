require 'sinatra'
require 'erb'
require 'open-uri'
require './model'

set :public_folder, File.dirname(__FILE__) + '/public'
set :views,         File.dirname(__FILE__) + '/views'



get '/' do
  erb :index
end

get '/songs/:id' do
  if request.xhr?
    content_type :json
    open(Song.data_url(params[:id])) do |f|
      {song: Song.from_json(f.read)}.to_json.to_s
    end
  else
    redirect "#/songs/#{params[:id]}"
  end
end