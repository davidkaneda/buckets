_ = require 'underscore'
express = require 'express'
path = require 'path'
async = require 'async'
User = require '../../models/user'
Deployment = require '../../models/deployment'
fs = require 'fs-extra'

module.exports = app = express()

# Just a proxy for Dropbox#delta
app.get '/deployments/dropbox/check', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator']

  client = req.user.getDropboxClient()

  return req.status(400).end() unless client

  cursor = req.user.dropbox?.cursor

  client.delta cursor: cursor, (status, reply) ->
    if status is 200 and reply?.entries
      reply.entries = _.reject reply.entries, (entry) -> entry[0].indexOf("/#{req.hostname}") isnt 0
    res.status(status).send(reply)

# This is the same code that called in preview mode
# Except it tells User#syncDropbox to not include a cursor
app.post '/deployments/dropbox/import', (req, res, next) ->
  return res.status(401).end() unless req?.user?.hasRole ['administrator']

  req.user.syncDropbox req.hostname, true, (e)->
    console.log 'Done live-syncing Dropbox for preview', arguments
    res.status(200).end()

# Takes the current user’s Dropbox and promotes it to live
app.get '/deployments/dropbox', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator'] and req.user?.dropbox?.token

  client = req.user.getDropboxClient()
  return res.status(500).end() unless client

  deployment = new Deployment
    author: user._id

app.post '/deployments', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator']

  deployment = new Deployment
    author: req.user._id

  res.send {status: 'started'}

  deployment.save ->
    # todo: websocket notification
    console.log 'postsave', arguments
    console.log arguments[0]?.errors?.source

app.get '/deployments', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator']

  Deployment.find().sort('-timestamp').select('-source').exec (e, deploys) ->
    res.status(200).send deploys
