PushtView = require './pusht-view'

require './pusher'

_ = require 'underscore'

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


    channel.bind 'pusher:subscription_succeeded', (members) ->
      console.log members.me.id

    triggerPush = true

    channel.bind 'client-change', (data) ->
      console.log data
      triggerPush = false
      if data.deletion
        buffer.delete data.oldRange
      # else if data.newRange.intersectsWith(data.oldRange)
        # console.log 'intersection'
      else
          # buffer.setTextInRange data.newRange, data.newText
          buffer.insert data.newRange.start, data.newText
      triggerPush = true

    buffer.onDidChange (event) ->

      return unless triggerPush

      console.log event


      return if (_.isEqual event.newRange, event.oldRange) and (event.newText is event.oldText)


      insertNewLine = (event.newText is "\n")
      deletion = !insertNewLine and (event.newText.length is 0)


      channel.trigger 'client-change',
        insertNewLine: insertNewLine
        deletion: deletion
        oldRange: event.oldRange
        newRange: event.newRange
        oldText: event.oldText
        newText: event.newText
#
