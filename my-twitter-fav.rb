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
    fname = session[:auth]['name'] + ".yml"
    raw = if File.exists? fname
      YAML::load(File.open(fname))
    else
      favs = get_all_favorites
      File.open(fname, 'w') do |out|
        YAML::dump(favs, out)
      end
      favs
    end
    # we end up with an array of [ [user1, count1, [user1-tweet1, user1-tweet2, ...] ], ... ] sorted by count
    # this should allow a simple display of top favorited-users, with their count, and drill down to the tweets
    display = raw.group_by {|o| o.user.screen_name }.map{|k,v| [k, v]}.sort_by{|o| o[1].length}.reverse.map{|o| [o[0], o[1].length, o[1]]}
    CTD + '<br/>' +
      "size #{raw.length}<br/>" +
      display.map{|o| "#{o[1]} #{o[0]}" }.join("<br/>")
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
    session[:auth] = env['omniauth.auth']['info']
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

  private
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def get_all_favorites
    collect_with_max_id do |max_id|
      options = {:count => 200}
      options[:max_id] = max_id unless max_id.nil?
      puts ">>> favorites #{options.inspect}"
      @client.favorites(options)
    end
  end
end
