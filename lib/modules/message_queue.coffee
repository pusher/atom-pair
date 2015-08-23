_ = require 'underscore'

module.exports =
class MessageQueue

  constructor: (@pusher) ->
    @items = []
    @cycle()

  cycle: ->
    @interval = setInterval(=>
      if @items.length > 0
        item = @items.shift()
        @pusher.channel(item.channel).trigger(item.event, item.payload)
    , 120)

  dispose: ->
    clearInterval(@interval)
    @items = []

  add: (channel, event, payload) ->
    lastItem = @items[@items.length - 1]
    if lastItem and lastItem.channel is channel and lastItem.event is event is 'client-change'
      item = {
        event: event,
        channel: channel,
        payload: _.flatten([lastItem.payload, payload])
      }
      @items[@items.length - 1] = item
    else
      item = {channel: channel, event: event, payload: payload}
      @items.push(item)
