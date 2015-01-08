PushtView = require './pusht-view'
StartView = require './start-view'
JoinView = require './join-view'

require './pusher'
$ = require 'jquery'
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
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:start new pairing session': => @start()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:join pairing session': => @join()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:id:copy': => @copyId()


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pushtView.destroy()

  serialize: ->
    pushtViewState: @pushtView.serialize()

  copyId: ->
    atom.clipboard.write(@sessionId)

  join: ->
    @joinView = new JoinView
    @joinPanel = atom.workspace.addModalPanel(item: @joinView, visible: true)
    @joinView.miniEditor.focus()

    @joinView.on 'core:confirm', =>
      @sessionId = @joinView.miniEditor.getText()
      @joinPanel.hide()
      @startPairing()

  start: ->

    $.get('http://localhost:3000/session/id').success (id) =>
      @sessionId = id
      @startView = new StartView(@sessionId)
      @startPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      @startView.focus()
      @startPairing()

  startPairing: ->

    triggerPush = true

    buffer = atom.workspace.getActiveEditor().buffer

    pusher = new Pusher 'd41a439c438a100756f5', {authEndpoint: 'http://localhost:3000/session/authenticate'}

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
