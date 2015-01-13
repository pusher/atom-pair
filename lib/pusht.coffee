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

    @colours = [
      "aqua",
      "aquamarine",
      "beige",
      "bisque",
      "black",
      "blanchedalmond",
      "blue",
      "blueviolet",
      "brown",
      "burlywood",
      "cadetblue",
      "chartreuse",
      "chocolate",
      "coral",
      "cornflowerblue",
      "cornsilk",
      "crimson",
      "cyan",
      "darkblue",
      "darkcyan",
      "darkgoldenrod",
      "darkgreen",
      "darkkhaki",
      "darkmagenta",
      "darkolivegreen",
      "darkorange",
      "darkorchid",
      "darkred",
      "darksalmon",
      "darkseagreen",
      "darkslateblue",
      "darkturquoise",
      "darkviolet",
      "deeppink",
      "deepskyblue",
      "dodgerblue",
      "firebrick",
      "forestgreen",
      "fuchsia",
      "gainsboro",
      "gold",
      "goldenrod",
      "green",
      "greenyellow",
      "hotpink",
      "indianred",
      "indigo",
      "khaki",
      "lavender",
      "lavenderblush",
      "lawngreen",
      "lightblue",
      "lightcoral",
      "lightgreen",
      "lightpink",
      "lightsalmon",
      "lightseagreen",
      "lightskyblue",
      "lightsteelblue",
      "lime",
      "limegreen",
      "magenta",
      "maroon",
      "mediumaquamarine",
      "mediumblue",
      "mediumorchid",
      "mediumpurple",
      "mediumseagreen",
      "mediumslateblue",
      "mediumspringgreen",
      "mediumturquoise",
      "mediumvioletred",
      "midnightblue",
      "mistyrose",
      "moccasin",
      "navy",
      "olive",
      "olivedrab",
      "orange",
      "orangered",
      "orchid",
      "palegoldenrod",
      "palegreen",
      "paleturquoise",
      "palevioletred",
      "papayawhip",
      "peachpuff",
      "peru",
      "pink",
      "plum",
      "powderblue",
      "purple",
      "red",
      "rosybrown",
      "royalblue",
      "saddlebrown",
      "salmon",
      "sandybrown",
      "seagreen",
      "sienna",
      "silver",
      "skyblue",
      "slateblue",
      "slategray",
      "springgreen",
      "steelblue",
      "tan",
      "teal",
      "thistle",
      "tomato",
      "turquoise",
      "violet",
      "yellow",
      "yellowgreen"
    ]

    @buddyMarkers = []

  deactivate: ->
    @subscriptions.dispose()

  disconnect: ->
    @pusher.disconnect()
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
      excludeColourIndex = keys[3]
      console.log excludeColourIndex
      colourIndex = _.without(_.range(@colours.length), excludeColourIndex)
      console.log colourIndex
      @markerColour = @colours[colourIndex]
      console.log @markerColour
      @joinPanel.hide()
      @startPairing()

  getKeysFromConfig: ->
    @app_key = atom.config.get 'pusher_app_key'
    @app_secret = atom.config.get 'pusher_app_secret'
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
    triggerPush = true
    @editor = atom.workspace.getActiveEditor()

    atom.views.getView(@editor).setAttribute('id', 'pusht')

    buffer = @buffer = @editor.buffer

    $('atom-text-editor#pusht::shadow .line-number.cursor-line').addClass(@markerColour)
    @syncMarker()

    @pusher = new Pusher @app_key,
      authTransport: 'client'
      clientAuth:
        key: @app_key
        secret: @app_secret
        user_id: "user"

    @pairingChannel = @pusher.subscribe("presence-session-#{@sessionId}")

    @pairingChannel.bind 'pusher:subscription_succeeded', (members) =>

      @pairingChannel.trigger 'client-joined', {joined:true}


    @pairingChannel.bind 'client-joined', (data) =>
      noticeView = new AlertView "Your pair buddy has joined the session."
      atom.workspace.addModalPanel(item: noticeView, visible: true)
      @sendGrammar()
      @syncGrammars()
      @shareCurrentFile(buffer)


    @pairingChannel.bind 'client-grammar-sync', (syntax) =>
      grammar = atom.grammars.grammarForScopeName(syntax)
      @editor.setGrammar(grammar)
      @syncGrammars()

    @pairingChannel.bind 'client-share-whole-file', (file) ->
      triggerPush = false
      buffer.setText(file)
      triggerPush = true

    @pairingChannel.bind 'client-share-partial-file', (chunk) ->
      triggerPush = false
      buffer.append(chunk)
      triggerPush = true

    @pairingChannel.bind 'client-change', (data) =>
      newRange = Range.fromObject(data.event.newRange)
      oldRange = Range.fromObject(data.event.oldRange)
      newText = data.event.newText

      triggerPush = false

      if data.deletion
        buffer.delete oldRange
        @editor.scrollToBufferPosition(oldRange.start)
      else if oldRange.containsRange(newRange)
        buffer.setTextInRange oldRange, newText
        @editor.scrollToBufferPosition(oldRange.start)
      else
        buffer.insert newRange.start, newText
        @editor.scrollToBufferPosition(newRange.start)

      triggerPush = true

    buffer.onDidChange (event) =>
      return unless triggerPush
      deletion = !(event.newText is "\n") and (event.newText.length is 0)
      @pairingChannel.trigger 'client-change', {deletion: deletion, event: event, cursorColour: @gutterColour}

  syncGrammars: ->
    @editor.on 'grammar-changed', => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @pairingChannel.trigger 'client-grammar-sync', grammar.scopeName

  syncMarker: ->

    lineCount = @editor.getLineCount()
    @editor.onDidChange =>
      setTimeout =>
        if (@editor.getLastBufferRow() + 1) > lineCount
          newLineNumber = @editor.getCursorBufferPosition().toArray()[0]
          $("atom-text-editor#pusht::shadow .line-number").each (index, line) =>
            $(line).removeClass(@markerColour)

          $("atom-text-editor#pusht::shadow .line-number-#{newLineNumber}").addClass(@markerColour)
          lineCount = @editor.getLineCount()
      , 100

    @editor.onDidChangeCursorPosition (event) =>
      if event.newBufferPosition.toArray()[0] isnt event.oldBufferPosition.toArray()[0]
        newLineNumber = event.newBufferPosition.toArray()[0]

        $("atom-text-editor#pusht::shadow .line-number").each (index, line) =>
          $(line).removeClass(@markerColour)

        $("atom-text-editor#pusht::shadow .line-number-#{newLineNumber}").addClass(@markerColour)

    @editor.onDidChangeSelectionRange (event) =>
      rows = event.newBufferRange.getRows()
      $("atom-text-editor#pusht::shadow .line-number").each (index, line) =>
        $(line).removeClass(@markerColour)
      _.each rows, (row) =>
        $("atom-text-editor#pusht::shadow .line-number-#{row}").addClass(@markerColour)


  shareCurrentFile: (buffer)->
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
