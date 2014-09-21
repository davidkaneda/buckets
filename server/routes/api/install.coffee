express = require 'express'
fs = require 'fs-extra'

User = require '../../models/user'
Bucket = require '../../models/bucket'
Entry = require '../../models/entry'
Route = require '../../models/route'
Deployment = require '../../models/deployment'

bucketSeed = require '../../models/seed/buckets'
routeSeed = require '../../models/seed/routes'
entrySeed = require '../../models/seed/entries'

module.exports = app = express()

app.post '/install', (req, res) ->
  User.count (err, count) ->

    return res.send err if err
    return res.status(400).send errors: [message: 'This deployment has already been installed.'] unless count is 0

    newUser = new User req.body
    newUser.roles = [name: 'administrator']

    renderError = (err) ->
      res.status(400).send err

    newUser.save (err, newUser) ->

      return renderError err if err
      # We should parallelize this at some point
      Route.create(routeSeed).then( ->
        Bucket.create bucketSeed
      ).then( (bucket) ->
        for entry in entrySeed
          entry.bucket = bucket.id
          entry.author = newUser.id
        Entry.create entrySeed
      , renderError).then ->
        fs.copy "./deployments/base/", "./deployments/#{newUser.email}", ->
          Deployment.create author: newUser.id
          req.login newUser, ->
            res.status(201).send newUser
