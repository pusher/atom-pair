{Emitter} = require 'atom'

module.exports =
  class PusherMock

    constructor: (@key, @secret) ->

    subscribe: ->
      new ChannelMock

    disconnect: ->

    channel: (arg)->
      @chan ?= new ChannelMock


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
