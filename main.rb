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

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17

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
      break if total <= BLACKJACK_AMOUNT
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

  def winner!(msg)
    @success = "<strong>#{session[:player_name]} wins!</strong> " + msg
    @play_again = true
  end

  def loser!(msg)
    @error = "<strong>#{session[:player_name]} loses.</strong> " + msg
    @play_again = true
  end

  def tie!(msg)
    @success= "<strong>It's a tie.</strong> " + msg
    @play_again = true
  end
end

before do
  @show_hit_or_stay_buttons = true
  @issue_dealer_card = false
  @show_dealer_score = false
end

get "/" do
  if session[:player_name]
    redirect '/game'
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

  if params[:player_name].match(/[^a-zA-Z]/)
    @error = "Need to enter alphabet letters only"
    halt erb(:form)
  end

  session[:player_name] = params[:player_name]
    redirect '/game'
  #:locals => {:player_name => params[:player_name]}
end

  get '/game' do
  #deck a deck and put it in session
  @first_greeting = true

  session[:turn] = session[:player_name]

  suits = ['H', 'D', 'C', 'S']
  values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
    @show_hit_or_stay_buttons = false
    @first_greeting = false
  end

  erb :game
end

post '/game/player/hit' do
  session[:turn] = session[:player_name]
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
    @show_hit_or_stay_buttons = false
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:player_name]} busted")
    @show_hit_or_stay_buttons = false
  end

  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"

  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Sorry, Dealer's got blackjack.")
    @show_dealer_score = true
  elsif  dealer_total > BLACKJACK_AMOUNT
    winner!("Yay, Dealer's busted.")
    @show_dealer_score = true
  elsif  dealer_total >= DEALER_HIT_MIN
    #dealer stops and scores are compared
    redirect '/game/compare'
  else
    #dealer takes another card
    @show_dealer_score = true
    @issue_dealer_card = true
  end

  erb :game
end


post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  @show_dealer_score = true

  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} while Dealer stayed at #{dealer_total}.")
  elsif player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} while Dealer stayed at #{dealer_total}.")
  else
    tie!("Both players have the score of #{player_total}.")
  end

  erb :game
end

post '/game/play_again' do
  redirect '/game'
end

get '/game_over' do
  erb :game_over
end
