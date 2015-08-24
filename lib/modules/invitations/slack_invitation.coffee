Invitation = require './invitation'
Slack = require 'slack-node'

module.exports =
class SlackInvitation extends Invitation

  needsInput:true
  askRecipientName: "Please enter the Slack name of your pair partner (or channel name):"

  checkConfig: ->
    if @session.missingSlackWebHook()
      atom.notifications.addError("Please set your Slack Incoming WebHook")
      false
    else
      true

  getSlack: -> new Slack()

  send: (done)->
    slack = @getSlack()
    slack.setWebhook @session.slack_url
    params =
      text: "Hello there #{@recipient}. You have been invited to a pairing session. If you haven't installed the AtomPair plugin, type \`apm install atom-pair\` into your terminal. Go onto Atom, hit 'Join a pairing session', and enter this string: #{@session.id}"
      channel: @recipient
      username: 'AtomPair'
      icon_emoji: ':couple_with_heart:'
    slack.webhook params, (err, response) =>
      atom.notifications.addInfo("#{@recipient} has been sent an invitation. Hold tight!")
      done()
