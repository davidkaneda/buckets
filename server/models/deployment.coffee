mongoose = require 'mongoose'
db = require '../lib/database'
archiver = require 'archiver'
async = require 'async'
fs = require 'fs-extra'
filesize = require 'filesize'
tarball = require 'tarball-extract'

deploymentSchema = new mongoose.Schema
  author:
    type: mongoose.Schema.Types.ObjectId
    ref: 'User'
    required: yes
  timestamp:
    type: Date
    default: Date.now
    index: yes
  dropbox: {}
  source:
    type: Buffer
    required: yes
,
  toJSON:
    virtuals: yes
    transform: (doc, ret, options) ->
      delete ret._id
      delete ret.__v
      ret
# Validation takes care of .tar.gz'ing the author’s env folder
# todo: Switch to GridFS and stream to it directly (as opposed to saving/deleting zip...)
deploymentSchema.pre 'validate', (next) ->

  author = @author

  mongoose.model('User').findById @author, (e, user) =>
    unless user
      @invalidate 'author', 'Not a valid User'
      return next()

    time = new Date().toISOString().replace(/\:/g, '.')
    filename = "./deployments/#{user.email}@#{time}.tar.gz"
    output = fs.createWriteStream filename
    output.on 'close', =>
      size = archive.pointer()
      console.log 'New deployment', filename, filesize size

      @invalidate 'source', 'File size too big' if size > 15000000 # Cap at 15mb for now
      @invalidate 'source', 'No content' if size is 0

      @source = fs.readFileSync(filename)

      # Move on to return response
      next()

      # Then delete the compressed version
      fs.remove filename

    archive = archiver.create 'tar', gzip: yes
    archive.on 'error', (err) ->
      throw err
      next()
    archive.pipe output
    archive.bulk
      expand: yes
      cwd: "./deployments/#{user.email}"
      src: ['**']
    archive.finalize()

# After deployment is saved, copy it over to live
deploymentSchema.post 'save', ->
  mongoose.model('User').findById @author, (e, user) ->
    throw e if e
    console.log 'well here we are', arguments
    debugger
    fs.copy "./deployments/#{user.email}", './deployments/live', ->
      console.log 'Successfully copied user directory to live.'

deploymentSchema.statics.scaffoldFromBase = ->
  console.log 'todo: Deployment#scaffoldFromBase'

  # This is more of a migration script at this point
  # This also happens during install
  mongoose.model('User').findOne 'roles.name': 'administrator', (err, user) =>
    return console.error err if err

    fs.copy "./deployments/base/", "./deployments/#{user.email}", =>
      @create author: user.id

  # This will create a deployment

# Writes a deployment to live
# (service agnostic at this point)
deploymentSchema.methods.unpack = ->
  # pipe file from MongoDB
  console.log 'Unpacking deployment'
  if @source
    tarPath = './deployments/staging.tar.gz'
    console.log "Creating #{tarPath}"
    fs.outputFile tarPath, @source.toObject()?.buffer, (e) ->
      throw e if e
      console.log 'Wrote Tarball from DB', error: e, path: tarPath
      fs.ensureDir './deployments/live/'
      tarball.extractTarball tarPath, './deployments/live/', ->
        console.log 'Extracted Tarball'
        fs.remove tarPath

deploymentSchema.statics.getLive = (callback) ->
  @findOne().sort('-timestamp').exec callback

module.exports = db.model 'Deployment', deploymentSchema
