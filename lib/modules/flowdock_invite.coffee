InputView = require '../views/input-view'
Flowdock = require 'flowdock'
_ = require 'underscore'

module.exports = FlowdockInvite =

  inviteOverFlowdock: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      atom.notifications.addError("Please set your Pusher keys.")
    else if @missingFlowdockKey()
      atom.notifications.addError("Please set your Flowdock API key.")
    else
      inviteView = new InputView("Please enter the Flowdock name of your pair partner (or flow name):")
      inviteView.miniEditor.focus()
      atom.commands.add inviteView.element, 'core:confirm': =>
        messageRcpt = inviteView.miniEditor.getText()
        inviteView.panel.hide()
        @sendFlowdockMessageTo(messageRcpt)


  sendFlowdockMessageTo: (messageRcpt) ->
    if _.isEmpty messageRcpt then return

    try
      @session = new Flowdock.Session(@flowdock_key)
      @session.on 'error', () -> _.noop  #prevent errors from affecting Atom
    catch error
      atom.notifications.addError("Could not connect to Flowdock. Please check your API key.")
      return

    @generateSessionId()

    inviteText = "Hello there #{messageRcpt}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: `#{@sessionId}`"

    recipient = @getRecipient(messageRcpt) # THIS DOES NOT WORK; ASYNC PROGRAMMING FAIL. Need to wait for @getRecipient to return. How?

    if recipient.type is 'user'
      # send a message to the user
      @session.privateMessage recipient.id, inviteText, (err, message, res) =>
        console.log 'Sending invite...'
        atom.notifications.addInfo("#{messageRcpt} has been sent an invitation. Hold tight!")
        @markerColour = @colours[0]
        @pairingSetup()
        return

    if recipient.type is 'flow'
      # send a message to the flow
      @session.message recipient.id, inviteText, (err, message, res) =>
        atom.notifications.addInfo("#{messageRcpt} has been sent an invitation. Hold tight!")
        @markerColour = @colours[0]
        @pairingSetup()
        return


  getRecipient: (messageRcpt) ->
    isNickLookup = messageRcpt.charAt(0) is '@'
    rcptAlias = if isNickLookup then messageRcpt.slice(1).toUpperCase() else messageRcpt.toUpperCase()

    # Can't be sure if we're inviting a user or a flow. Try users then flows.
    @session.get '/users', {}, (err, message, res) ->
      if err then atom.notifications.addError("Could not fetch Flowdock users.")

      users = res.body
      userRcpt = _.find users, (user) ->
        if isNickLookup
          return rcptAlias is user.nick.toUpperCase()
        else
          return rcptAlias is user.nick.toUpperCase() or rcptAlias is user.name.toUpperCase()

      if userRcpt
        console.log userRcpt
        return {type: 'user', id: userRcpt.id}

    # check flows if we're still emptyhanded and not searching nicks
    if !isNickLookup
      @session.flows (err, flows) ->
        flowRcpt = _.find flows, (flow) ->
          rcptAlias is flow.name.toUpperCase() or rcptAlias is flow.parameterized_name.toUpperCase()

        if flowRcpt
          console.log flowRcpt
          return {type: 'flow', id: flowRcpt.id}

        atom.notifications.addError("Could not find a flow or user matching #{messageRcpt}.")
