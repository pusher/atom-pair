StartView = require './views/start-view'
InputView = require './views/input-view'
ConfigView = require './views/config-view'
AlertView = require './views/alert-view'

require './pusher/pusher'
require './pusher/pusher-js-client-auth'

randomstring = require 'randomstring'
_ = require 'underscore'
chunkString = require './helpers/chunk-string'

HipChatInvite = require './modules/hipchat_invite'
Marker = require './modules/marker'
GrammarSync = require './modules/grammar_sync'
AtomPairConfig = require './modules/atom_pair_config'

{CompositeDisposable} = require 'atom'
{Range} = require 'atom'

module.exports = AtomPair =
  AtomPairView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @editorListeners = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:start new pairing session': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:join pairing session': => @joinSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:set configuration keys': => @setConfig()
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:invite over hipchat': => @inviteOverHipChat()

    atom.commands.add 'atom-workspace', 'AtomPair:hide views': => @hidePanel()
    atom.commands.add '.session-id', 'AtomPair:copyid': => @copyId()

    @colours = require('./helpers/colour-list')
    @friendColours = []
    @timeouts = []
    @events = []
    _.extend(@, HipChatInvite, Marker, GrammarSync, AtomPairConfig)

  disconnect: ->
    @pairingChannel.trigger 'client-disconnected', {colour: @markerColour}
    setTimeout((=>
      @pusher.disconnect()
      @editorListeners.dispose()
      )
    ,500)
    _.each @friendColours, (colour) => @clearMarkers(colour)
    atom.views.getView(@editor).removeAttribute('id')
    @hidePanel()

  copyId: ->
    atom.clipboard.write(@sessionId)

  hidePanel: ->
    _.each atom.workspace.getModalPanels(), (panel) -> panel.hide()

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

      atom.workspace.open().then => @startPairing()

  startSession: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      alertView = new AlertView "Please set your Pusher keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      @generateSessionId()
      @startView = new StartView(@sessionId)
      @startPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      @startView.focus()
      @startPairing()

  generateSessionId: ->
    colourIndex = _.random(0, @colours.length)
    @markerColour = @colours[colourIndex]
    @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}-#{colourIndex}"

  startPairing: ->
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:disconnect': => @disconnect()
    @triggerPush = true
    @editor = atom.workspace.getActiveEditor()
    atom.views.getView(@editor).setAttribute('id', 'AtomPair')

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

    @pairingChannel.bind 'client-change', (events) =>
      _.each(events, (event) =>
        @changeBuffer(event) if event.eventType is 'buffer-change'
        if event.eventType is 'buffer-selection'
          @updateCollaboratorMarker(event)
      )

    @pairingChannel.bind 'client-disconnected', (data) =>
      @clearMarkers(data.colour)
      disconnectView = new AlertView "Your pair buddy has left the session."
      atom.workspace.addModalPanel(item: disconnectView, visible: true)

    @triggerEventQueue()

    @editorListeners.add @listenToBufferChanges()
    @editorListeners.add @syncSelectionRange()

    @listenForDestruction()

  listenForDestruction: ->
    @editorListeners.add @buffer.onDidDestroy => @disconnect()
    @editorListeners.add @editor.onDidDestroy => @disconnect()

  updateCollaboratorMarker: (data) ->
    @clearMarkers(data.colour)
    @markRows(data.rows, data.colour)

  listenToBufferChanges: ->
    @buffer.onDidChange (event) =>
      return unless @triggerPush
      deletion = !(event.newText is "\n") and (event.newText.length is 0)
      event = {deletion: deletion, event: event, colour: @markerColour, eventType: 'buffer-change'}
      @events.push(event)

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
      @events.push {eventType: 'buffer-selection', colour: @markerColour, rows: rows}

  triggerEventQueue: ->
    @eventInterval = setInterval(=>
      if @events.length > 0
        @pairingChannel.trigger 'client-change', @events
        @events = []
    , 120)

  shareCurrentFile: (buffer) ->
    currentFile = buffer.getText()
    return if currentFile.length is 0
    size = Buffer.byteLength(currentFile, 'utf8')

    if size < 1000
      @pairingChannel.trigger 'client-share-whole-file', currentFile
    else
      chunks = chunkString(currentFile, 950)
      _.each chunks, (chunk, index) =>
        setTimeout(( => @pairingChannel.trigger 'client-share-partial-file', chunk), 180 * index)
