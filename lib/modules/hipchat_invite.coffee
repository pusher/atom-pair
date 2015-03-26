InputView = require '../views/input-view'
AlertView = require '../views/alert-view'
HipChat = require 'node-hipchat'
_ = require 'underscore'

module.exports = HipChatInvite =

  inviteOverHipChat: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      new AlertView "Please set your Pusher keys."
    else if @missingHipChatKeys()
      new AlertView "Please set your HipChat keys."
    else
      inviteView = new InputView("Please enter the HipChat mention name of your pair partner:")
      inviteView.miniEditor.focus()
      inviteView.on 'core:confirm', =>
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
        keyErrorView = new AlertView "Something went wrong. Please check your HipChat keys."
        return

      params =
        room: room_id
        from: 'AtomPair'
        message: "Hello there #{collaboratorsString}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: #{@sessionId}"
        message_format: 'text'

      hc_client.postMessage params, (data) =>
        if collaboratorsArray.length > 1 then verb = "have" else verb = "has"
        new AlertView "#{collaboratorsString} #{verb} been sent an invitation. Hold tight!"
        @startPairing()
