PushtView = require './pusht-view'
StartView = require './start-view'

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

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pushtView.destroy()

  serialize: ->
    pushtViewState: @pushtView.serialize()

  join: ->


  start: ->

    sessionId = null
    triggerPush = true


    editor = atom.workspace.getActiveEditor()
    buffer = editor.buffer

    pusher = new Pusher 'd41a439c438a100756f5'

    pairingChannel = null

    $.get('http://localhost:3000/session/id').success (id) ->
      sessionId = id
      @startView = new StartView(sessionId)
      @modalPanel = atom.workspace.addModalPanel(item: @startView, visible: true)
      pairingChannel = pusher.subscribe("session-#{sessionId}")
      startPairing()

    startPairing = ->
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
