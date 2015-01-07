PushtView = require './pusht-view'

require './pusher'

_ = require 'underscore'

JSDiff = require 'diff'

{CompositeDisposable} = require 'atom'

module.exports = Pusht =
  pushtView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->

    @pushtView = new PushtView(state.pushtViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @pushtView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'pusht:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pushtView.destroy()

  serialize: ->
    pushtViewState: @pushtView.serialize()

  toggle: ->

    editor = atom.workspace.getActiveEditor()

    buffer = editor.buffer

    pusher = new Pusher 'd41a439c438a100756f5', { authEndpoint: 'http://localhost:3000/presence/auth' }

    channel = pusher.subscribe('presence-pairing')

    me = null

    lastEvent = null

    channel.bind 'pusher:subscription_succeeded', (members) ->
      me =  members.me.id

    triggerPush = true

    channel.bind 'client-change', (data) ->
      if data.deletion
        buffer.delete data.oldRange
      else
        # unless !lastEvent or ((data.newText is lastEvent.newText) and (_.isEqual data.newRange, lastEvent.newRange))
        if !lastEvent or !((data.newText is lastEvent.newText) and (_.isEqual data.newRange, lastEvent.newRange))
          # console.log data.newText
          # console.log lastEvent.newText
          # console.log (data.newText is lastEvent.newText)
          #
          # console.log "-------------"
          #
          # console.log data.newRange
          # console.log lastEvent.newRange
          # console.log (_.isEqual data.newRange, lastEvent.newRange)

          triggerPush = false
          buffer.setTextInRange data.newRange, data.newText
      triggerPush = true

    buffer.onDidChange (event) ->
      console.log "BUG!!"
      lastEvent = event
      deletion = (event.newText.length is 0)
      if triggerPush then channel.trigger 'client-change', {deletion: deletion, oldRange: event.oldRange, newRange: event.newRange, oldText: event.oldText, newText: event.newText}
