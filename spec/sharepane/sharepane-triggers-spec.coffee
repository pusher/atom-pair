_ = require 'underscore'
bufferTriggerTest = require '../helpers/buffer-triggers'
{Range} = require 'atom'
specSetup = require '../helpers/spec-setup'

describe "sharePane", ->

  awaitPromises = (ctx)->
    waitsForPromise -> ctx.activationPromise
    waitsForPromise -> ctx.openedEditor

  beforeEach ->
    specSetup(@)

  describe 'triggers', ->
    it 'sends the right event for a basic one-line typing', ->
      awaitPromises(@)
      runs ->
        queue = @sharePane.queue
        spyOn queue, 'add'
        bufferTriggerTest @buffer, 'basic-buffer-write', queue, =>
          _.each 'hello world', (char, index) =>
            @buffer.insert([0, index], char)

    it 'sends the right event for an insert + linebreak', ->
      awaitPromises(@)
      runs ->
        queue = @sharePane.queue
        spyOn queue, 'add'
        bufferTriggerTest @buffer, 'insert-and-line-break', queue, =>
          _.each 'hello world', (char, index) => @buffer.insert([0, index], char)
          @buffer.insert([0, 6], "\n")

    it 'handles deletions', ->
      awaitPromises(@)
      runs ->
        queue = @sharePane.queue
        spyOn queue, 'add'
        bufferTriggerTest @buffer, 'small-deletions', queue, =>
          _.each 'hello world', (char, index) => @buffer.insert([0, index], char)
          @buffer.delete(new Range([0, 10], [0,11]))
          @buffer.delete(new Range([0, 9], [0,10]))
          @buffer.delete(new Range [0,1], [0,2])

    it 'handles multiline deletions', ->
      awaitPromises(@)
      runs ->
        queue = @sharePane.queue
        spyOn queue, 'add'
        bufferTriggerTest @buffer, 'multiline-deletions', queue, =>
          @buffer.setText("i have of late\nwherefore i know not\nlost all my mirth\nand indeed it goes so heavily with my disposition\nthat this goodly frame the earth\nseems to me\na sterile promontory :(")
          range = new Range([3,0], [4,32])
          @buffer.delete(range)

    it 'handles large insertions + substituting it for small', ->
      awaitPromises(@)
      runs ->
        queue = @sharePane.queue
        spyOn queue, 'add'
        fs = require 'fs'
        davidCopperfield = fs.readFileSync 'spec/fixtures/david_copperfield.txt', {encoding: 'utf8'}
        argsForCall = require '../fixtures/large-text-for-small'
        @buffer.setText(davidCopperfield)
        @buffer.setTextInRange(new Range([0,0], [313, 0]), 'l')
        _.each 'ala', (char, index) => @buffer.insert([0, index + 1], char)
        expect(queue.add.argsForCall).toEqual(argsForCall)

describe 'sharefile', ->

  awaitPromises = (ctx)->
    waitsForPromise -> ctx.activationPromise
    waitsForPromise -> ctx.openedEditor

  it 'sends the right event for a small file', ->
    specSetup(@, "I'm a little teapot short and stout")
    awaitPromises(@)

    runs ->
      spyOn(@sharePane.queue, 'add')
      @sharePane.shareFile()
      expect(@sharePane.queue.add.argsForCall).toEqual([ [ 'test-channel', 'client-share-whole-file', "I'm a little teapot short and stout" ] ])

  it 'sends the right event for a large file', ->
    fs = require 'fs'
    davidCopperfield = fs.readFileSync 'spec/fixtures/david_copperfield.txt', {encoding: 'utf8'}
    specSetup(@, davidCopperfield)
    awaitPromises(@)

    runs ->
      spyOn(@sharePane.queue, 'add')
      @sharePane.shareFile()
      argsForCall = require('../fixtures/large-text-for-small')[0..84]
      expect(@sharePane.queue.add.argsForCall).toEqual(argsForCall)
