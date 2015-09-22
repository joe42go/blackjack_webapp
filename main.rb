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

helpers do
  def calculate_total(cards)
    total = 0
    cards.each do |card|
      if card[1] == 'A'
        total += 11
      elsif card[1].to_i != 0
        total += card[1].to_i
      else
        total += 10
      end
    end

    cards.select {|card| card[1]=="A"}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_image(card) # ['H','4']
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J','Q','K','A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

          "<img class='card_image' src='/images/cards/#{suit}_#{value}.jpg'>"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get "/" do
  if session[:player_name]
    redirect '/bet'
  else
    erb :welcome
  end
end

get "/form" do
  erb :form
end

post '/form' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:form)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
  #:locals => {:player_name => params[:player_name]}
end

get '/bet' do
  #deck a deck and put it in session
  suits = ['H', 'D', 'C', 'S']
  values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :bet
end

post '/bet/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:player_name]} hit blackjack!"
    @shot_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, It looks like #{session[:player_name]} busted"
    @show_hit_or_stay_buttons = false
  end

  erb :bet
end

post '/bet/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay"
  @show_hit_or_stay_buttons = false
  erb :bet
end