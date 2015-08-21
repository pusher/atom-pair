_ = require 'underscore'

module.exports =
class User

  @colours: require('../helpers/colour-list')

  @reset: ->
    @me = null
    @all = []

  @availableColours: ->
    _.reject @colours, (colour) => _.any @all, (user) -> user.colour is colour

  @nextAvailableColour: ->
    @availableColours()[0]

  @all: []

  @withColour: (colour) ->
    _.findWhere @all, {colour: colour}

  @allButMe: ->
    _.reject @all, (user) -> user is User.me

  @addMe: ->
    @me = @add(@nextAvailableColour())

  @add: (colour = @nextAvailableColour(), arrivalTime = new Date().getTime())->
    user = new User(colour, arrivalTime)
    @all.push(user)
    user

  @remove: (colour)->
    @all = _.reject @all, (user) -> user.colour is colour

  @me: null

  constructor: (@colour, @arrivalTime)->

  isLeader: ->
    leader = _.sortBy(@constructor.all, 'arrivalTime')[0]
    @arrivalTime is leader.arrivalTime
