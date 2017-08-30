Invitation = require './invitation'
HipChat = require 'node-hipchat'
_ = require 'underscore'

module.exports =
class HipChatInvitation extends Invitation

  needsInput: true
  askRecipientName: "Please enter the HipChat mention name of your pair partner:"

  checkConfig: ->
    if @session.missingHipChatKeys()
      atom.notifications.addError("Please set your HipChat keys.")
      false
    else
      true

  getHipChat: ->
    new HipChat(@session.hc_key)

  send: (done) ->
    collaboratorsArray = @recipient.match(/\w+/g)
    collaboratorsString = _.map(collaboratorsArray, (collaborator) ->
      "@" + collaborator unless collaborator[0] is "@"
    ).join(", ")

    hc_client = @getHipChat()

    hc_client.listRooms (data) =>
      try
        room_id = _.findWhere(data.rooms, {name: @session.room_name}).room_id
      catch error
        atom.notifications.addError("Something went wrong. Please check your HipChat keys.")
        return

      params =
        room: room_id
        from: 'AtomPair'
        message: "Hello there #{collaboratorsString}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: #{@session.id}"
        message_format: 'text'

      hc_client.postMessage params, (data) =>
        if collaboratorsArray.length > 1 then verb = "have" else verb = "has"
        atom.notifications.addInfo("#{collaboratorsString} #{verb} been sent an invitation. Hold tight!")
        done()
