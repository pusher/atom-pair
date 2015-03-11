InputView = require '../views/input-view'
AlertView = require '../views/alert-view'
Slack = require 'slack-node'
_ = require 'underscore'

module.exports = SlackInvite =

  inviteOverSlack: ->
    @getKeysFromConfig()

    if @missingPusherKeys()
      alertView = new AlertView "Please set your Pusher keys."
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else if @missingSlackWebHook()
      alertView = new AlertView "Please set your Slack Incoming WebHook"
      atom.workspace.addModalPanel(item: alertView, visible: true)
    else
      inviteView = new InputView("Please enter the Slack name of your pair partner (or channel name):")
      invitePanel = atom.workspace.addModalPanel(item: inviteView, visible: true)
      inviteView.on 'core:confirm', =>
        messageRcpt = inviteView.miniEditor.getText()
        @sendSlackMessageTo(messageRcpt)
        invitePanel.hide()

  sendSlackMessageTo: (messageRcpt) ->
    #prepare the slack stuff
    slack = new Slack()
    slack.setWebhook @slack_url
    #generate the sessionid
    @generateSessionId()
    #create params
    params =
      text: "Hello there #{messageRcpt}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: #{@sessionId}"
      channel: messageRcpt
      username: 'AtomPair'
      icon_emoji: ':couple_with_heart:'
    #send a message to the user
    slack.webhook params, (err, response) =>
      alertView = new AlertView "#{messageRcpt} has been sent an invitation. Hold tight!"
      atom.workspace.addModalPanel(item: alertView, visible: true)
      @markerColour = @colours[0]
      @pairingSetup()
      return
