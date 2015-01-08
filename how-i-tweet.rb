require 'yaml'
require 'sinatra/base'
require 'omniauth-twitter'
require 'twitter'

class HowITweet < Sinatra::Base
  #set :server, 'webrick' # this OR start Rack http://stackoverflow.com/a/17335819

  # recommend keeping secrets.yml in .gitignore
  secrets = File.join(Dir.pwd, 'secrets.yml')
  $secrets = if settings.environment == :development and File.exists?(secrets)
               YAML.load_file(secrets)
             else
               {}
             end

  $consumer_key = ENV['TWITTER_CONSUMER_KEY'] || $secrets[:twitter_consumer_key]
  $consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || $secrets[:twitter_consumer_secret]
  CTD = '<a href="/">continue</a>'
  STYLE = '<style>a{text-decoration:none;}td{padding:0 3px 0 0;}</style>'

  use OmniAuth::Builder do
    provider :twitter, $consumer_key, $consumer_secret
  end

  configure do
    enable :sessions
  end

  helpers do
    def authed?
      return session[:auth] &&
        @client ||= Twitter::REST::Client.new do |secrets|
          secrets.consumer_key = $consumer_key
          secrets.consumer_secret = $consumer_secret
          secrets.access_token = session[:access_token]
          secrets.access_token_secret = session[:access_token_secret]
        end
    end

    def h(text)
      Rack::Utils.escape_html(text)
    end
  end

  get '/' do
    if authed?
      '<a href="/profile">profile</a>, ' +
      '<a href="/favorites">favorites</a>, ' +
      '<a href="/retweets">retweets</a>, ' +
      '<a href="/logout">logout</a>'
    else
      '<a href="/login">login</a>'
    end
  end

  get '/favorites' do
    halt(401,'Not Authorized ' + CTD) unless authed?
    raw = cache('favorites') do
      get_all_favorites
    end

    raw = raw.group_by {|o| o.user.screen_name }
    render_raw(raw, 'favorites')
  end

  get '/retweets' do
    halt(401,'Not Authorized ' + CTD) unless authed?
    raw = cache('retweets') do
      get_all_retweets
    end

    raw = raw.group_by {|o| o.retweeted_status.user.screen_name }
    render_raw(raw, 'retweets')
  end

  get '/profile' do
    halt(401,'Not Authorized ' + CTD) unless authed?
    CTD +
        "<br/><img src=\"#{@client.user.profile_image_uri}\"> #{@client.user.name} " +
        "<br/>#{@client.user.description}"
  end

  get '/login' do
    redirect to('/auth/twitter')
  end

  get '/auth/twitter/callback' do
    halt(401,'Not Authorized ' + CTD) if ! env['omniauth.auth']
    session[:auth] = env['omniauth.auth']['info']
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    CTD +
        "<br/><img src=\"#{env['omniauth.auth']['info']['image']}\">" +
        " Logged in as #{env['omniauth.auth']['info']['name']} "
  end

  get '/auth/failure' do
    params[:message] + CTD
  end

  get '/logout' do
    session[:auth] = nil
    'You are now logged out. ' + CTD
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
      @client.favorites(options)
    end
  end

  def get_all_retweets
    # this is going to hit a 3,200 tweet limit defined by the API as it grabs these from the entire timeline :(
    collect_with_max_id do |max_id|
      options = {:count => 200}
      options[:max_id] = max_id unless max_id.nil?
      @client.retweeted_by_me(options)
    end
  end

  def render_raw(raw, name)
    # we end up with an array of [ [user1, count1, [user1-tweet1, user1-tweet2, ...] ], ... ] sorted by count
    # this should allow a simple display of top favorited-users, with their count, and drill down to the tweets
    # we expect raw to have already been grouped by the relevant user (different for favs and rts)
    display = raw.map{|k,v| [k, v]}
                  .sort_by{|o| o[1].length}
                  .reverse.map{|o| [o[0], o[1].length, o[1]]}
    STYLE + CTD +
        '<br/>' +
        "##{name} #{raw.length}<br/>" +
        "#users #{display.length}<br/><br/>" +
        '<table>' + # no really, this is tabular data
        display.each_with_index.map{|o, i|
          '<tr>' +
              "<td>#{i+1}</td>" +
              "<td>#{o[1]}</td>" +
              "<td><a href=\"https://twitter.com/#{o[0]}\">#{o[0]}</a></td>" +
              "<td>" +
              o[2].map{ |t| "<a href=\"https://twitter.com/#{o[0]}/status/#{t.id}\" title=\"#{h(t.text)}\">*</a>"}.join +
              '</td>'
        }.join('<tr/>') +
        '</table>' +
        '<br/>' + CTD
  end

  def cache(name)
    # not-smart cache to avoid rate limits, we dump it after 15 minutes (rate limit window)
    # really need a good cache strategy allowing in-fill of favs and rts in the middle of the timeline
    # without in-fill this will confuse folks for now, oh well
    # also not sure that freshness time comparison is going to work reliably, ctime and now same TZ? mebbe :)
    # note also on Heroku we can sort-of rely on this local tmp/ - it's good enough for now
    fname = File.join('tmp', session[:auth]['nickname'] + '-' + name + '.yml')
    if File.exists? fname and File.ctime(fname) + (15 * 60) > Time.now
      YAML::load(File.open(fname))
    else
      items = yield
      File.open(fname, 'w') do |out|
        YAML::dump(items, out)
      end
      items
    end
  end
end
