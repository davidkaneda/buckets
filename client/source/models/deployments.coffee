Collection = require 'lib/collection'
Deployment = require 'models/deployment'

module.exports = class Buckets extends Collection
  url: '/api/deployments'
  model: Deployment
  comparator: 'timestamp'
