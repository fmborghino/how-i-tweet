require 'yaml'
require 'sinatra'
require 'omniauth-twitter'

$config = YAML.load_file(File.join(Dir.pwd, 'config.yml'))

use OmniAuth::Builder do
  consumer_key = ENV['TWITTER_CONSUMER_KEY'] || $config[:twitter_consumer_key]
  consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || $config[:twitter_consumer_secret]
  provider :twitter, consumer_key, consumer_secret
end

configure do
  enable :sessions
end

helpers do
  def admin?
    session[:admin]
  end
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
  env['omniauth.auth'] ? session[:admin] = true : halt(401,'Not Authorized')
  "<img src='#{env['omniauth.auth']['info']['image']}'> You are logged in #{env['omniauth.auth']['info']['name']}!"
end

get '/auth/failure' do
  params[:message]
end

get '/logout' do
  session[:admin] = nil
  "You are now logged out"
end
