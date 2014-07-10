require 'yaml'
require 'sinatra/base'
require 'omniauth-twitter'
require 'twitter'

class MyTwitterFav < Sinatra::Base
  #set :server, 'webrick' # this or start Rack http://stackoverflow.com/a/17335819
  $config = YAML.load_file(File.join(Dir.pwd, 'config.yml'))
  $consumer_key = ENV['TWITTER_CONSUMER_KEY'] || $config[:twitter_consumer_key]
  $consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || $config[:twitter_consumer_secret]
  CTD = '<a href="/">continue</a>'

  use OmniAuth::Builder do
    provider :twitter, $consumer_key, $consumer_secret
  end

  configure do
    enable :sessions
  end

  helpers do
    def authed?
      return session[:auth] &&
        @client ||= Twitter::REST::Client.new do |config|
          config.consumer_key = $consumer_key
          config.consumer_secret = $consumer_secret
          config.oauth_token = session[:access_token]
          config.oauth_token_secret = session[:access_token_secret]
        end
    end
  end

  get '/' do
    if authed?
      '<a href="/profile">profile</a>, <a href="/favorites">favorites</a>, <a href="/logout">logout</a>'
    else
      '<a href="/login">login</a>'
    end
  end

  get '/favorites' do
    halt(401,'Not Authorized ' + CTD) unless authed?
    @users = {}
    @favs = []
    @favs.push(*@client.favorites(count:200))
    @favs.each do |e|
      screen_name = e['user']['screen_name']
      @users[screen_name] = e['user']
    end
    CTD + '<br/>' +
      "#{@users} "
  end

  get '/profile' do
    halt(401,'Not Authorized ' + CTD) unless authed?
    "#{@client.user.name} " + CTD
  end

  get '/public' do
    "This is the public page - everybody is welcome! " + CTD
  end

  get '/private' do
    halt(401,'Not Authorized') unless authed?
    "This is the private page - members only " + CTD
  end

  get '/login' do
    redirect to("/auth/twitter")
  end

  get '/auth/twitter/callback' do
    halt(401,'Not Authorized ' + CTD) if ! env['omniauth.auth']
    session[:auth] = true
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    "<img src='#{env['omniauth.auth']['info']['image']}'> You are logged in #{env['omniauth.auth']['info']['name']}! " + CTD
  end

  get '/auth/failure' do
    params[:message] + CTD
  end

  get '/logout' do
    session[:auth] = nil
    "You are now logged out. " + CTD
  end

  run! if app_file == $0
end
