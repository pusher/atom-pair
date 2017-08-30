{CompositeDisposable} = require 'atom'

Invitation = null
HipChatInvitation = null
SlackInvitation = null
Session = null
_ = null

module.exports = AtomPair =

  AtomPairView: null
  modalPanel: null
  subscriptions: null

  config:
    hipchat_token:
      type: 'string'
      description: 'HipChat admin token (optional)'
      default: ''
    hipchat_room_name:
      type: 'string'
      description: 'HipChat room name for sending invitations (optional)'
      default: ''
    pusher_app_key:
      type: 'string'
      description: 'Pusher App Key (sign up at http://pusher.com/signup and change for added security)'
      default: 'd41a439c438a100756f5'
    pusher_app_secret:
      type: 'string'
      description: 'Pusher App Secret'
      default: '4bf35003e819bb138249'
    slack_url:
      type: 'string'
      description: 'WebHook URL for Slack Incoming Webhook Integration'
      default: ''

  activate: (state) ->
    _ = require 'underscore'
    Invitation = require './modules/invitations/invitation'
    HipChatInvitation = require './modules/invitations/hipchat_invitation'
    SlackInvitation = require './modules/invitations/slack_invitation'
    Session = require './modules/session'

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:start new pairing session': =>
      Session.initiate(Invitation)
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:invite over hipchat': =>
      Session.initiate(HipChatInvitation)
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:invite over slack': =>
      Session.initiate(SlackInvitation)
    @subscriptions.add atom.commands.add 'atom-workspace', 'AtomPair:join pairing session': =>
      Session.join()
