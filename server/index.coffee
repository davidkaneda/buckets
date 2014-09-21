dotenv = require 'dotenv'
dotenv.load()

_ = require 'underscore'
colors = require 'colors'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
session = require 'cookie-session'
compression = require 'compression'
responseTime = require 'response-time'
express = require 'express'
hbs = require 'hbs'

Deployment = require './models/deployment'

class Buckets
  constructor: (config) ->
    @config = _.extend require('./config'), config

    Deployment.findOne().sort('-timestamp').exec (err, deployment) =>
      if deployment
        setTimeout ->
          deployment.unpack()
        , 0
      else
        Deployment.scaffoldFromBase()

      try
        newrelicConfig = require '../newrelic'
        if newrelicConfig.config.license_key
          newrelic = require 'newrelic'
          console.log 'NewRelic '.cyan + 'On'
          hbs.registerHelper 'newrelic', ->
            new hbs.handlebars.SafeString newrelic.getBrowserTimingHeader()
      catch e
        console.log 'There was an error loading NewRelic', e

      # Purge Fastly on prod pushes
      if @config.fastly?.api_key and @config.fastly?.service_id and @config.env is 'production'
        fastly = require('fastly')(@config.fastly.api_key)
        fastly.purgeAll @config.fastly.service_id, -> console.log 'Purged Fastly Cache'.red

      passport = require './lib/auth'

      @routers =
        admin: require './routes/admin'
        api: require './routes/api'
        frontend: require './routes/frontend'

      @app = express()

      @app.use (req, res, next) ->
        req.startTime = Date.now()
        next()

      # Handle cookies and sessions and stuff
      @app.use compression level: 4
      @app.use responseTime() if @config.env isnt 'production'
      @app.use cookieParser @config.salt
      @app.use session
        secret: @config.salt
        name: 'buckets'
      @app.use bodyParser.json()
      @app.use bodyParser.urlencoded extended: true
      @app.use passport.initialize()
      @app.use passport.session()

      @app.set 'view engine', 'hbs'

      # Load Routes for the API, admin, and frontend
      @app.use "/#{@config.apiSegment}", @routers.api
      @app.use "/#{@config.adminSegment}", @routers.admin
      @app.use @routers.frontend

      @start() if @config.autoStart

  start: (done) ->
    done?() if @server
    @server ?= @app.listen @config.port, =>
      console.log ("\nBuckets is running at " + "http://localhost:#{@config.port}/".underline.bold).yellow
      done?()

  stop: (done) ->
    done?() unless @server
    @server.close done

# There can be only one #highlander
buckets = null
module.exports = (config={}) ->
  buckets ?= new Buckets config
