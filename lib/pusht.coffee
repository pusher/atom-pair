PushtView = require './pusht-view'
StartView = require './start-view'
JoinView = require './join-view'
ConfigView = require './config-view'
AlertView = require './alert-view'


require './pusher'
require './pusher-js-client-auth'

randomstring = require 'randomstring'
_ = require 'underscore'


{CompositeDisposable} = require 'atom'

Range = require('atom').Range

module.exports = Pusht =
  pushtView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    @pushtView = new PushtView(state.pushtViewState)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:start new pairing session': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:join pairing session': => @joinSession()

    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:set configuration keys': => @setConfig()

    atom.commands.add '.session-id', 'pusht:copyid': => @copyId()


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pushtView.destroy()

  serialize: ->
    pushtViewState: @pushtView.serialize()

  copyId: ->
    atom.clipboard.write(@sessionId)

  setConfig: ->
    @configView = new ConfigView
    @configPanel = atom.workspace.addModalPanel(item: @configView, visible: true)

    @configView.on 'core:confirm', =>
      _.each ['pusher_app_key', 'pusher_app_secret'], (key) =>
        value = @configView[key].getText()
        atom.config.set(key, value)
      @configPanel.hide()



  joinSession: ->
    @joinView = new JoinView
    @joinPanel = atom.workspace.addModalPanel(item: @joinView, visible: true)
    @joinView.miniEditor.focus()

    @joinView.on 'core:confirm', =>
      @sessionId = @joinView.miniEditor.getText()
      keys = @sessionId.split("-")
      [@app_key, @app_secret] = [keys[0], keys[1]]
      @joinPanel.hide()
      @startPairing()

  startSession: ->

    @app_key = atom.config.get 'pusher_app_key'
    @app_secret = atom.config.get 'pusher_app_secret'

    missingKeys = _.any([@app_key, @app_secret], (key) ->
      typeof(key) is "undefined")

    if missingKeys
      alertView = new AlertView
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      string = randomstring.generate(11)
      @sessionId = "#{@app_key}-#{@app_secret}-#{string}"
      @startView = new StartView(@sessionId)
      @startPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      @startView.focus()
      @startPairing()

  startPairing: ->

    triggerPush = true

    buffer = atom.workspace.getActiveEditor().buffer

    pusher = new Pusher @app_key,
      authTransport: 'client'
      clientAuth:
        key: @app_key
        secret: @app_secret

    pairingChannel = pusher.subscribe("private-session-#{@sessionId}")

    pairingChannel.bind 'client-change', (data) ->

      newRange = Range.fromObject(data.event.newRange)
      oldRange = Range.fromObject(data.event.oldRange)
      newText = data.event.newText

      triggerPush = false

      if data.deletion
        buffer.delete oldRange
      else if oldRange.containsRange(newRange)
        buffer.setTextInRange oldRange, newText
      else
        buffer.insert newRange.start, newText

      triggerPush = true

    buffer.onDidChange (event) ->
      return unless triggerPush
      deletion = !(event.newText is "\n") and (event.newText.length is 0)
      pairingChannel.trigger 'client-change', {deletion: deletion, event: event}
