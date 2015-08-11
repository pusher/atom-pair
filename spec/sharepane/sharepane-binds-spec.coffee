_ = require 'underscore'
bufferTriggerTest = require '../helpers/buffer-triggers'
specSetup = require '../helpers/spec-setup.coffee'

describe "sharePane:binds", ->

  awaitPromises = (ctx)->
    waitsForPromise -> ctx.activationPromise
    waitsForPromise -> ctx.openedEditor

  beforeEach ->
    specSetup(@)

  describe 'sharePane:binds', ->

    it 'should create the right text from an event', ->
      awaitPromises(@)
      runs ->
        testEvents = require '../fixtures/basic-buffer-write'
        _.each testEvents, (event) =>
          @sharePane.channel.fakeSend('client-change', event)
        result = @buffer.getText()
        expect(result).toBe('hello world')

    it 'should handle insert + linebreak', ->
      awaitPromises(@)
      runs ->
        testEvents = require '../fixtures/insert-and-line-break'
        _.each testEvents, (event) =>
          @sharePane.channel.fakeSend('client-change', event)
        result = @buffer.getText()
        expect(result).toBe("hello \nworld")

    it 'should handle deletions', ->
      awaitPromises(@)
      runs ->
        testEvents = require '../fixtures/small-deletions'
        _.each testEvents, (event) =>
          @sharePane.channel.fakeSend('client-change', event)
        result = @buffer.getText()
        expect(result).toBe("hllo wor")

    it 'should handle multiline deletions', ->
      awaitPromises(@)
      runs ->
        testEvents = require '../fixtures/multiline-deletions'
        _.each testEvents, (event) =>
          @sharePane.channel.fakeSend('client-change', event)
        result = @buffer.getText()
        expected = "i have of late\nwherefore i know not\nlost all my mirth\n\nseems to me\na sterile promontory :("
        expect(result).toBe(expected)

    it 'handles large insertations + subsituting it for small', ->
      awaitPromises(@)
      runs ->
        fs = require 'fs'
        davidCopperfield = fs.readFileSync 'spec/fixtures/david_copperfield.txt', {encoding: 'utf8'}
        testEvents = require '../fixtures/large-text-for-small'
        _.each testEvents, (event, index) =>
          @sharePane.channel.fakeSend(event[1], event[2])
          if index is 84 then expect(@buffer.getText()).toEqual(davidCopperfield)

        result = @buffer.getText()
        expect(result).toBe('lala')
