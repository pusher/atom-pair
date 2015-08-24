_ = require 'underscore'

module.exports = bufferTriggerTest = (buffer, fileName, queue, action)->
  expectedEvents = require "../fixtures/#{fileName}"
  action(buffer)

  argsForCall = _.map expectedEvents, (expected) ->
    ['test-channel', 'client-change', expected]

  expect(queue.add.argsForCall).toEqual(argsForCall)
