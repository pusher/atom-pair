{Emitter} = require 'atom'
_ = require 'underscore'

module.exports =
  class PusherMock

    constructor: (@key, @secret) ->
      @connected = true

    subscribe: ->
      new ChannelMock

    disconnect: ->
      @connected = false

    channel: (arg)->
      @chan ?= new ChannelMock

    mockMembers: (members) ->
      new Members members


class ChannelMock

  name: 'test-channel'

  constructor: ->
    @emitter = new Emitter

  fakeSend: (event, data) ->
    @emitter.emit(event, data)

  bind: (event, callback)->
    @emitter.on event, callback

  trigger: (evt, payload) ->

  unsubscribe: ->

class Members

  constructor: (@members) ->
    @members ?= []

  each: (fn)->
    _.each @members, fn
