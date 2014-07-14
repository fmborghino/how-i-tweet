# Simple tools to explore past Twitter activity

## What we have here
- Sinatra, OmniAuth, twitter, Heroku
- Simple sorted display of all the users you have favorited, explore the
  tweets
- Other similar tools to follow, include
    - Sorted display of users you have retweeted and replied to
    - Search over all your past tweets

## Setup
- rbenv or rvm
- gem install bundler
- bundle install

## API Tokens
Get Twitter app secrets from https://apps.twitter.com/app/new

## Dev mode usage
TWITTER_CONSUMER_KEY=your_key TWITTER_CONSUMER_SECRET=your_secret rerun rackup

Else set in secrets.yml. Recommend you don't check this in.

## Heroku setup
Preferably set these with

    heroku config:set TWITTER_CONSUMER_KEY=your_key
    heroku config:set TWITTER_CONSUMER_SECRET=your_secret

## Heroku deploy
    git push heroku master

## Heroku usage
    heroku open

Or visit http://your-app-name.herokuapp.com

## References
- Handy OmniAuth with Sinatra intro
  http://www.sitepoint.com/twitter-authentication-in-sinatra/
- Added twitter gem with controller examples from
  https://github.com/sferik/sign-in-with-twitter

# TODO

- Pick a cache strategy for Heroku, continue to use file system for dev
    - S3 https://devcenter.heroku.com/articles/s3
    - memcachedcloud
      https://devcenter.heroku.com/articles/memcachedcloud
    - ironcache https://devcenter.heroku.com/articles/iron_cache
