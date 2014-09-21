express = require 'express'
path = require 'path'
async = require 'async'
User = require '../../models/user'
Deployment = require '../../models/deployment'
fs = require 'fs-extra'

module.exports = app = express()

# Just a proxy for Dropbox#delta
app.get '/deployments/dropbox/check', (req, res) ->
  return res.status(401).end() unless req?.user?.hasRole ['administrator']

  User.findOne {dropbox: $exists: yes}, (e, user) ->
    return res.send 'No user!' unless user
    return res.send 'No token!' unless user.dropbox.token

    client = user.getDropboxClient()

    client.delta (status, reply) -> res.status(status).send(reply)

# This is the same code that called in preview mode
# Except it tells User#syncDropbox to not include a cursor
app.get '/deployments/dropbox/import', (req, res) ->
  return res.status(401).end() unless req?.user?.hasRole ['administrator']

  req.user.syncDropbox req.hostname, true, (e)->
    console.log 'Done live-syncing Dropbox for preview', arguments
    next()

# Takes the current user’s Dropbox and promotes it to live
app.get '/deployments/dropbox', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator'] and req.user?.dropbox?.token

  client = req.user.getDropboxClient()
  return res.status(500).end() unless client

  deployment = new Deployment
    author: user._id

app.post '/deployments/dropbox', (req, res) ->
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
    console.log 'postsave', arguments
    console.log arguments[0]?.errors?.source

app.get '/deployments', (req, res) ->
  return res.status(401).end() unless req.user?.hasRole ['administrator']

  Deployment.find().sort('-timestamp').select('-source').exec (e, deploys) ->
    res.status(200).send deploys
