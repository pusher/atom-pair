_ = require 'underscore'
PresenceIndicator = require './presence_indicator'

module.exports =
class User

  @colours: require('../helpers/colour-list')

  @clear: ->
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

  @clearIndicators: ->
    _.each User.all, (user) => user.clearIndicators()

  constructor: (@colour, @arrivalTime)->

  isLeader: ->
    leader = _.sortBy(@constructor.all, 'arrivalTime')[0]
    @arrivalTime is leader.arrivalTime

  remove: ->
    User.remove(@colour)

  clearIndicators: ->
    PresenceIndicator.clearMarkers(@colour)

  updatePosition: (tab, rows)->
    PresenceIndicator.updateCollaboratorMarker(@colour, rows)
    PresenceIndicator.setActiveIcon(tab, @colour)
