# Simple tools to explore past Twitter activity

## What we have here
- Sinatra, OmniAuth, twitter gem, Heroku
- As little UI as possible, think CLI level
- Simple sorted display of all the users you have favorited or retweeted
- Little attention to rate limits (15 minute dumb cache), this will blow up on large initial datasets (for now)
- Probably live at http://howitweet.herokuapp.com

## Setup
- bake your favorite ruby gem env
- gem install bundler
- bundle install

## API Tokens
Get your own Twitter app tokens from https://apps.twitter.com/app/new

## Dev mode usage
TWITTER_CONSUMER_KEY=your_key TWITTER_CONSUMER_SECRET=your_secret rerun rackup

Else set those in secrets.yml. Recommend you don't commit that file!

## Heroku setup
Set your secrets with

    heroku config:set TWITTER_CONSUMER_KEY=your_key
    heroku config:set TWITTER_CONSUMER_SECRET=your_secret

## Heroku deploy
    git push heroku master

## Heroku usage
    heroku open

Or visit http://your-app-name.herokuapp.com

## References
- [OmniAuth with Sinatra intro](http://www.sitepoint.com/twitter-authentication-in-sinatra/)
- [Twitter gem examples](https://github.com/sferik/sign-in-with-twitter)

## Todo

- Need to handle hitting rate limits
- Pick a sensible cache strategy that accounts for favs and rts anywhere in the timeline
- Pick a cache for Heroku (continue to use file system for dev), options...
    - [S3](https://devcenter.heroku.com/articles/s3)
    - [memcachedcloud](https://devcenter.heroku.com/articles/memcachedcloud)
    - [ironcache](https://devcenter.heroku.com/articles/iron_cache)
