PusherMock = require '../pusher-mock'
MessageQueue = require '../../lib/modules/message_queue'
specSetup = require '../helpers/spec-setup.coffee'
_ = require 'underscore'

describe 'messagequeue', ->

  activationPromise = null

  beforeEach ->
    activationPromise = atom.packages.activatePackage('atom-pair')
    pusher = new PusherMock 'key', 'secret'
    @queue_ = new MessageQueue pusher

  describe 'q', ->

    it 'should not send more than 10 messages a second', ->

      waitsForPromise -> activationPromise

      runs ->
        channel = @queue_.pusher.channel('test-channel')
        spyOn(channel, 'trigger')
        jasmine.Clock.useMock()
        jasmine.Clock.tick(1001)
        for num in [1..100]
          @queue_.add('test-channel', 'event', {hello: 'world'})

        rateLimit = channel.trigger.argsForCall.length > 10
        expect(rateLimit).toBe(false)

    it 'batches same-pane typing events', ->

      waitsForPromise -> activationPromise

      runs ->
        @queue_.cycle = ->
        for event in ['test1', 'test2', 'test3']
          @queue_.add('test-channel', 'client-change', event)
        for event in ['test4, test5', 'test6']
          @queue_.add('test-channel2', 'client-change', event)
        @queue_.add('test-channel2', 'client-buffer-selection',  {
          "colour": "blue",
          "rows": [
            0,
            1
          ]
        })
        expect(@queue_.items.length).toBe(3)

    it 'disposes correctly', ->
      waitsForPromise -> activationPromise
      runs ->
        channel = @queue_.pusher.channel('test-channel')
        spyOn(channel, 'trigger')
        @queue_.add('test-channel', 'event', {hello: 'world'})
        @queue_.dispose()
        expect(@queue_.items.length).toBe(0)
        @queue_.add('test-channel', 'event', {hello: 'world'})
        jasmine.Clock.useMock()
        jasmine.Clock.tick(1001)
        expect(channel.trigger).not.toHaveBeenCalled()
