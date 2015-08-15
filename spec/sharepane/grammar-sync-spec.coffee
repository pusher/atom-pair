_ = require 'underscore'
bufferTriggerTest = require '../helpers/buffer-triggers'
{Range} = require 'atom'
specSetup = require '../helpers/spec-setup'

describe "sharePane", ->

  awaitPromises = (ctx)->
    waitsForPromise -> ctx.activationPromise
    waitsForPromise ->
      ctx.openedEditor

  beforeEach ->
    specSetup(@)

  describe 'grammarSync', ->

    it 'sends grammar upon grammar change', ->
      awaitPromises(@)

      waitsForPromise ->
        atom.packages.activatePackage('language-ruby')

      runs ->
        queue = @sharePane.queue
        spyOn(queue, 'add') unless queue.add.isSpy
        editor = @sharePane.editor
        grammar = atom.grammars.grammarForScopeName('source.ruby')
        editor.setGrammar(grammar)
        expect(queue.add.argsForCall).toEqual([ [ 'test-channel', 'client-grammar-sync', 'source.ruby' ] ])

    it 'handles grammar sync message', ->
      awaitPromises(@)
      waitsForPromise ->
        atom.packages.activatePackage('language-ruby')

      runs ->
        @sharePane.channel.fakeSend('client-grammar-sync', 'source.ruby')
        editor = @sharePane.editor
        grammar = editor.getGrammar().scopeName
        expect(grammar).toBe('source.ruby')
