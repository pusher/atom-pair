PushtView = require './pusht-view'
StartView = require './start-view'
InputView = require './input-view'
ConfigView = require './config-view'
AlertView = require './alert-view'

require './pusher'
require './pusher-js-client-auth'

randomstring = require 'randomstring'
_ = require 'underscore'

HipChat = require 'node-hipchat'

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

    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:invite over hipchat': => @inviteOverHipChat()


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
      _.each ['pusher_app_key', 'pusher_app_secret', 'hipchat_token', 'hipchat_room_id'], (key) =>
        value = @configView[key].getText()
        atom.config.set(key, value) unless value.length is 0
      @configPanel.hide()



  joinSession: ->
    @joinView = new InputView("Enter the session ID here:")
    @joinPanel = atom.workspace.addModalPanel(item: @joinView, visible: true)
    @joinView.miniEditor.focus()

    @joinView.on 'core:confirm', =>
      @sessionId = @joinView.miniEditor.getText()
      keys = @sessionId.split("-")
      [@app_key, @app_secret] = [keys[0], keys[1]]
      @joinPanel.hide()
      @startPairing()

  getKeysFromConfig: ->
    @app_key = atom.config.get 'pusher_app_key'
    @app_secret = atom.config.get 'pusher_app_secret'

  missingKeys: ->
    _.any([@app_key, @app_secret], (key) ->
      typeof(key) is "undefined")

  startSession: ->
    @getKeysFromConfig()

    if @missingKeys()
      alertView = new AlertView "Please set your Pusher keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}"
      @startView = new StartView(@sessionId)
      @startPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      @startView.focus()
      @startPairing()

  inviteOverHipChat: ->
    @getKeysFromConfig()

    if @missingKeys()
      alertView = new AlertView
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      inviteView = new InputView("Please enter the HipChat mention name of your pair partner:")
      invitePanel = atom.workspace.addModalPanel(item: inviteView, visible: true)
      inviteView.on 'core:confirm', =>
        mentionName = inviteView.miniEditor.getText()
        @sendHipChatMessageTo(mentionName)
        invitePanel.hide()

  sendHipChatMessageTo: (mentionName) ->

    hc_key = atom.config.get 'hipchat_token'
    room_id = atom.config.get 'hipchat_room_id'

    hc_client = new HipChat(hc_key)

    @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}"

    params = {
      room: room_id,
      from: 'PusherPair',
      message: "Hello there #{mentionName}. Somebody really really wants to pair with you. Go onto Atom, and if you've installed the PusherPair plugin, hit 'Join a pairing session', and enter this string: #{@sessionId}",
      message_format: 'text'
    }

    hc_client.postMessage params, (data) ->
      alertView = new AlertView "#{mentionName} has been sent an invitation. Hold tight!"
      atom.workspace.addModalPanel(item: alertView, visible: true)


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
