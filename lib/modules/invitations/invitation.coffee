InputView = require '../../views/input-view'
User = require '../user'

module.exports =
class Invitation

  constructor: (@session) ->
    @invite()

  configPresent: ->
    @session.getKeysFromConfig()
    if @session.missingPusherKeys()
      atom.notifications.addError('Please set your Pusher keys.')
      return false
    if @checkConfig then @checkConfig() else true

  getRecipientName: (cta, callback)->
    inviteView = new InputView(cta)
    inviteView.miniEditor.focus()
    atom.commands.add inviteView.element, 'core:confirm': =>
      @recipient = inviteView.miniEditor.getText()
      inviteView.panel.hide()
      callback()

  afterSend: ->
    User.addMe() unless User.me
    @session.pairingSetup()

  invite: ->
    return unless @configPresent()
    if @needsInput
      @getRecipientName @askRecipientName, => @send => @afterSend()
    else
      atom.clipboard.write(@session.id)
      atom.notifications.addInfo "Your session ID has been copied to your clipboard."
      @afterSend() unless @session.active
