{CompositeDisposable} = require 'atom'

Invitation = null
HipChatInvitation = null
SlackInvitation = null
Session = null

module.exports = AtomPair =

  AtomPairView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
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
