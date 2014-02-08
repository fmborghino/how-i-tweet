require 'yaml'
require 'sinatra/base'
require 'omniauth-twitter'

class MyApp < Sinatra::Base
  $config = YAML.load_file(File.join(Dir.pwd, 'config.yml'))
  $consumer_key = ENV['TWITTER_CONSUMER_KEY'] || $config[:twitter_consumer_key]
  $consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || $config[:twitter_consumer_secret]

  use OmniAuth::Builder do
    provider :twitter, $consumer_key, $consumer_secret
  end

  configure do
    enable :sessions
  end

  helpers do
    def admin?
      session[:admin]
    end
  end

  get '/profile' do
    halt(401,'Not Authorized') unless admin?
    require 'twitter'
    client = Twitter::REST::Client.new do |config|
      config.consumer_key = $consumer_key
      config.consumer_secret = $consumer_secret
      config.oauth_token = session[:access_token]
      config.oauth_token_secret = session[:access_token_secret]
    end
    "#{client.user.name}"
  end

  get '/public' do
    "This is the public page - everybody is welcome!"
  end

  get '/private' do
    halt(401,'Not Authorized') unless admin?
    "This is the private page - members only"
  end

  get '/login' do
    redirect to("/auth/twitter")
  end

  get '/auth/twitter/callback' do
    halt(401,'Not Authorized') if ! env['omniauth.auth']
    session[:admin] = true
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    "<img src='#{env['omniauth.auth']['info']['image']}'> You are logged in #{env['omniauth.auth']['info']['name']}!"
  end

  get '/auth/failure' do
    params[:message]
  end

  get '/logout' do
    session[:admin] = nil
    "You are now logged out"
  end

  run! if app_file == $0
end
