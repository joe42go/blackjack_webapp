require 'rubygems'
require 'sinatra'

#set :sessions, true

configure :development do
  set :bind, '0.0.0.0'
  set :port, 3000 # Not really needed, but works well with the "Preview" menu option
end

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

get "/" do
  erb :welcome
end

get "/form" do
  erb :form
end

post '/bet' do
  @player_name = params[:player_name]
  erb :bet
  #:locals => {:player_name => params[:player_name]}
end