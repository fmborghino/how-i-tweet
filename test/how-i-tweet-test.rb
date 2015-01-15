ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'ostruct'

Dir.glob('./lib/*.rb').each {|f| require f}

require_relative '../how-i-tweet.rb'

class MockTwitterClient
  def user
    new OpenStruct({ profile_image_url: 'img.png', description: 'blah', name: 'yo' })
  end
end

class HowITweetTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def auth_info
    { 'rack.session' => { auth: OmniAuth.config.mock_auth[:twitter]['info'] } }
  end

  def get_with_auth(path, params={})
    get path, params, auth_info
  end

  def app
    HowITweet.new
  end

  def setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:twitter, {:uid => '12345', :nickname => 'Bob'})
  end

  def teardown
    OmniAuth.config.mock_auth[:twitter] = nil
  end

  def test_is_this_thing_on?
    assert_equal(true, true)
  end

  def test_root
    get '/'
    assert last_response.ok?
    assert last_response.body.include? 'login'
  end

  def test_profile
    #app.send('twitter_client=', MockTwitterClient.new)
    get_with_auth '/profile'
    puts last_response.inspect
    assert last_response.ok?
  end
end