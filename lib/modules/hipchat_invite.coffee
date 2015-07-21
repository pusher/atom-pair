InputView = require '../views/input-view'
AlertView = require '../views/alert-view'
HipChat = require 'node-hipchat'
_ = require 'underscore'

module.exports = HipChatInvite =

  inviteOverHipChat: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      atom.notifications.addError("Please set your Pusher keys.")
    else if @missingHipChatKeys()
      atom.notifications.addError("Please set your HipChat keys.")
    else
      inviteView = new InputView("Please enter the HipChat mention name of your pair partner:")
      inviteView.miniEditor.focus()
      atom.commands.add inviteView.element, 'core:confirm': =>
        mentionNames = inviteView.miniEditor.getText()
        @sendHipChatMessageTo(mentionNames)
        inviteView.panel.hide()

  sendHipChatMessageTo: (mentionNames) ->

    collaboratorsArray = mentionNames.match(/\w+/g)
    collaboratorsString = _.map(collaboratorsArray, (collaborator) ->
      "@" + collaborator unless collaborator[0] is "@"
    ).join(", ")

    hc_client = new HipChat(@hc_key)

    @generateSessionId()

    hc_client.listRooms (data) =>

      try
        room_id = _.findWhere(data.rooms, {name: @room_name}).room_id
      catch error
        atom.notifications.addError("Something went wrong. Please check your HipChat keys.")
        return

      params =
        room: room_id
        from: 'AtomPair'
        message: "Hello there #{collaboratorsString}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: #{@sessionId}"
        message_format: 'text'

      hc_client.postMessage params, (data) =>
        if collaboratorsArray.length > 1 then verb = "have" else verb = "has"
        atom.notifications.addInfo("#{collaboratorsString} #{verb} been sent an invitation. Hold tight!")
        @markerColour = @colours[0]
        @pairingSetup()
