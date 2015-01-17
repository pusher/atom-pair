StartView = require './views/start-view'
InputView = require './views/input-view'
ConfigView = require './views/config-view'
AlertView = require './views/alert-view'

require './pusher/pusher'
require './pusher/pusher-js-client-auth'

randomstring = require 'randomstring'
_ = require 'underscore'
$ = require 'jquery'
chunkString = require './helpers/chunk-string'

HipChat = require 'node-hipchat'

{CompositeDisposable} = require 'atom'
{Range} = require 'atom'

module.exports = Pusht =
  pushtView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:start new pairing session': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:join pairing session': => @joinSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:set configuration keys': => @setConfig()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:invite over hipchat': => @inviteOverHipChat()

    atom.commands.add 'atom-workspace', 'pusht:hide views': => @hidePanel()
    atom.commands.add '.session-id', 'pusht:copyid': => @copyId()

    @colours = require('./helpers/colour-list')
    @friendColours = []
    @timeouts = []

  deactivate: ->
    @subscriptions.dispose()

  disconnect: ->
    # @pairingChannel.trigger 'client-disconnected', {colour: @markerColour}
    @pusher.disconnect()
    _.each @friendColours, (colour) => @clearMarkers(colour)
    atom.views.getView(@editor).removeAttribute('id')
    @hidePanel()

  serialize: ->
    pushtViewState: @pushtView.serialize()

  copyId: ->
    atom.clipboard.write(@sessionId)

  hidePanel: ->
    _.each atom.workspace.getModalPanels(), (panel) -> panel.hide()

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

      takenColour = @colours[keys[3]]
      @assignColour(takenColour)

      @joinPanel.hide()
      @startPairing()

  assignColour: (takenColour) ->
    colour = _.sample(@colours)
    if colour is takenColour then assignColour()

    data = {colour: takenColour}
    @receiveFriendInfo(data)
    @markerColour = colour


  getKeysFromConfig: ->
    @app_key = atom.config.get('pusher_app_key') || 'd41a439c438a100756f5'
    @app_secret = atom.config.get('pusher_app_secret') || '4bf35003e819bb138249'
    @hc_key = atom.config.get 'hipchat_token'
    @room_id = atom.config.get 'hipchat_room_id'

  missingPusherKeys: ->
    _.any([@app_key, @app_secret], (key) ->
      typeof(key) is "undefined")

  missingHipChatKeys: ->
    _.any([@hc_key, @room_id], (key) ->
      typeof(key) is "undefined")

  startSession: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      alertView = new AlertView "Please set your Pusher keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      colourIndex = _.random(0, @colours.length)
      @markerColour = @colours[colourIndex]
      @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}-#{colourIndex}"
      @startView = new StartView(@sessionId)
      @startPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      @startView.focus()
      @startPairing()

  inviteOverHipChat: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      alertView = new AlertView "Please set your Pusher keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else if @missingHipChatKeys()
      alertView = new AlertView "Please set your HipChat keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      inviteView = new InputView("Please enter the HipChat mention name of your pair partner:")
      invitePanel = atom.workspace.addModalPanel(item: inviteView, visible: true)
      inviteView.on 'core:confirm', =>
        mentionName = inviteView.miniEditor.getText()
        @sendHipChatMessageTo(mentionName)
        invitePanel.hide()

  sendHipChatMessageTo: (mentionName) ->
    hc_client = new HipChat(@hc_key)

    @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}"

    params =
      room: @room_id
      from: 'PusherPair'
      message: "Hello there #{mentionName}. Somebody really really wants to pair with you. Go onto Atom, and if you've installed the PusherPair plugin, hit 'Join a pairing session', and enter this string: #{@sessionId}"
      message_format: 'text'

    hc_client.postMessage params, (data) =>
      alertView = new AlertView "#{mentionName} has been sent an invitation. Hold tight!"
      atom.workspace.addModalPanel(item: alertView, visible: true)
      @startPairing()


  startPairing: ->
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:disconnect': => @disconnect()
    @triggerPush = true
    @editor = atom.workspace.getActiveEditor()
    atom.views.getView(@editor).setAttribute('id', 'pusht')

    buffer = @buffer = @editor.buffer

    @pusher = new Pusher @app_key,
      authTransport: 'client'
      clientAuth:
        key: @app_key
        secret: @app_secret
        user_id: "user"

    @pairingChannel = @pusher.subscribe("presence-session-#{@sessionId}")

    @pairingChannel.bind 'pusher:subscription_succeeded', (members) =>
      @pairingChannel.trigger 'client-joined', {colour: @markerColour}

    @pairingChannel.bind 'client-joined', (data) =>
      noticeView = new AlertView "Your pair buddy has joined the session."
      atom.workspace.addModalPanel(item: noticeView, visible: true)
      @sendGrammar()
      @syncGrammars()
      @shareCurrentFile(buffer)
      @receiveFriendInfo(data)
      @pairingChannel.trigger 'client-broadcast-initial-marker', {colour: @markerColour}

    @pairingChannel.bind 'client-broadcast-initial-marker', (data) => @receiveFriendInfo(data)

    @pairingChannel.bind 'client-text-select', (data) =>
      @clearMarkers(data.colour)
      @markRows(data.rows, data.colour)

    @pairingChannel.bind 'client-grammar-sync', (syntax) =>
      grammar = atom.grammars.grammarForScopeName(syntax)
      @editor.setGrammar(grammar)
      @syncGrammars()

    @pairingChannel.bind 'client-share-whole-file', (file) =>
      @triggerPush = false
      buffer.setText(file)
      @triggerPush = true

    @pairingChannel.bind 'client-share-partial-file', (chunk) =>
      @triggerPush = false
      buffer.append(chunk)
      @triggerPush = true

    @pairingChannel.bind 'client-change', (data) => @changeBuffer(data)

    # @pairingChannel.bind 'client-disconnected', (data) =>
    #   @clearMarkers(data.colour)
    #   disconnectView = new AlertView "Your pair buddy has left the session."
    #   atom.workspace.addModalPanel(item: disconnectView, visible: true)


    @listenToBufferChanges()
    @syncSelectionRange()

  listenToBufferChanges: ->
    @buffer.onDidChange (event) =>
      return unless @triggerPush
      deletion = !(event.newText is "\n") and (event.newText.length is 0)
      @pairingChannel.trigger 'client-change', {deletion: deletion, event: event, colour: @markerColour}

  changeBuffer: (data) ->
    newRange = Range.fromObject(data.event.newRange)
    oldRange = Range.fromObject(data.event.oldRange)
    newText = data.event.newText

    @triggerPush = false

    @clearMarkers(data.colour)

    if data.deletion
      @buffer.delete oldRange
      @editor.scrollToBufferPosition(oldRange.start)
      @addMarker oldRange.start.toArray()[0], data.colour
    else if oldRange.containsRange(newRange)
      @buffer.setTextInRange oldRange, newText
      @editor.scrollToBufferPosition(oldRange.start)
      @addMarker oldRange.start.toArray()[0], data.colour
    else
      @buffer.insert newRange.start, newText
      @editor.scrollToBufferPosition(newRange.start)
      @addMarker(newRange.end.toArray()[0], data.colour)

    @triggerPush = true

  syncSelectionRange: ->
    @editor.onDidChangeSelectionRange (event) =>
      rows = event.newBufferRange.getRows()
      return unless rows.length > 1
      @pairingChannel.trigger 'client-text-select', {colour: @markerColour, rows: rows}

  receiveFriendInfo: (data) ->
    friendInfo = {colour: data.colour}
    unless _.contains(@friendColours, friendInfo.colour)
      @friendColours.push(data.colour)
    unless friendInfo.markerSeen
      @addMarker 0, data.colour
      friendInfo.markerSeen = true

  syncGrammars: ->
    @editor.on 'grammar-changed', => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @pairingChannel.trigger 'client-grammar-sync', grammar.scopeName

  markRows: (rows, colour) ->
    _.each rows, (row) => @addMarker(row, colour)

  clearMarkers: (colour) ->
    $("atom-text-editor#pusht::shadow .line-number").each (index, line) =>
      $(line).removeClass(colour)

  addMarker: (line, colour) ->
    element = $("atom-text-editor#pusht::shadow .line-number-#{line}")
    if element.length is 0
      @timeouts.push(setTimeout((=> @addMarker(line,colour)), 50))
    else
      _.each @timeouts, (timeout) -> clearTimeout(timeout)
      element.addClass(colour)


  shareCurrentFile: (buffer) ->
    currentFile = buffer.getText()
    return if currentFile.length is 0
    size = Buffer.byteLength(currentFile, 'utf8')

    if size < 1000
      @pairingChannel.trigger 'client-share-whole-file', currentFile
    else
      chunks = chunkString(currentFile, 950)
      chunksPerSecond = chunks.length / 10
      _.each chunks, (chunk) =>
        setTimeout(( => @pairingChannel.trigger 'client-share-partial-file', chunk), chunksPerSecond)
