require 'sinatra'
require 'erb'
require './model'

set :public_folder, File.dirname(__FILE__) + '/public'
set :views,         File.dirname(__FILE__) + '/views'



get '/' do
  erb :index
end

get '/songs/:id' do
  if request.xhr?
    content_type :json
    {song: Song.get(params[:id])}.to_json.to_s
  else
    redirect "#/songs/#{params[:id]}"
  end
end