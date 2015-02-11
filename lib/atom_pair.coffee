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
    @pusher.disconnect()
    @editorListeners.dispose()
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
      @joinPanel.hide()

      atom.workspace.open().then => @pairingSetup() #starts a new tab to join pairing session

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
      @markerColour = @colours[0]
      @pairingSetup()

  generateSessionId: ->
    @sessionId = "#{@app_key}-#{@app_secret}-#{randomstring.generate(11)}"

  pairingSetup: ->
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:disconnect': => @disconnect()
    @editor = atom.workspace.getActiveEditor()
    atom.views.getView(@editor).setAttribute('id', 'AtomPair')
    @connectToPusher()
    @synchronizeColours()

  connectToPusher: ->
    @pusher = new Pusher @app_key,
      authTransport: 'client'
      clientAuth:
        key: @app_key
        secret: @app_secret
        user_id: @markerColour || "blank"

    @pairingChannel = @pusher.subscribe("presence-session-#{@sessionId}")

  synchronizeColours: ->
    @pairingChannel.bind 'pusher:subscription_succeeded', (members) =>
      @membersCount = members.count
      return @resubscribe() unless @markerColour
      colours = Object.keys(members.members)
      @friendColours = _.without(colours, @markerColour)
      _.each(@friendColours, (colour) => @addMarker 0, colour)
      @startPairing()

  resubscribe: ->
    @pairingChannel.unsubscribe()
    @markerColour = @colours[@membersCount - 1]
    @connectToPusher()
    @synchronizeColours()

  startPairing: ->

    @triggerPush = true
    buffer = @buffer = @editor.buffer

    # listening for Pusher events

    @pairingChannel.bind 'pusher:member_added', (member) =>
      noticeView = new AlertView "Your pair buddy has joined the session."
      atom.workspace.addModalPanel(item: noticeView, visible: true)
      @sendGrammar()
      @syncGrammars()
      @shareCurrentFile(buffer)
      @friendColours.push(member.id)
      @addMarker 0, member.id
      @pairingChannel.trigger 'client-broadcast-initial-marker', {colour: @markerColour}

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
      _.each events, (event) =>
        @changeBuffer(event) if event.eventType is 'buffer-change'
        if event.eventType is 'buffer-selection'
          @updateCollaboratorMarker(event)

    @pairingChannel.bind 'pusher:member_removed', (member) =>
      @clearMarkers(member.id)
      disconnectView = new AlertView "Your pair buddy has left the session."
      atom.workspace.addModalPanel(item: disconnectView, visible: true)

    @triggerEventQueue()

    # listening for buffer events
    @editorListeners.add @listenToBufferChanges()
    @editorListeners.add @syncSelectionRange()

    # listening for its own demise
    @listenForDestruction()

  listenForDestruction: ->
    @editorListeners.add @buffer.onDidDestroy => @disconnect()
    @editorListeners.add @editor.onDidDestroy => @disconnect()

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
      actionArea = oldRange.start
    else if oldRange.containsRange(newRange)
      @buffer.setTextInRange oldRange, newText
      actionArea = oldRange.start
    else
      @buffer.insert newRange.start, newText
      actionArea = newRange.start

    @editor.scrollToBufferPosition(actionArea)
    @addMarker(actionArea.toArray()[0], data.colour)

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

    if currentFile.length < 950
      @pairingChannel.trigger 'client-share-whole-file', currentFile
    else
      chunks = chunkString(currentFile, 950)
      _.each chunks, (chunk, index) =>
        setTimeout(( => @pairingChannel.trigger 'client-share-partial-file', chunk), 180 * index)
