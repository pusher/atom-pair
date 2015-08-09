InputView = require '../../views/input-view'

module.exports =
class Invitation

  constructor: (@package) ->
    @invite()

  configPresent: ->
    @package.getKeysFromConfig()
    if @package.missingPusherKeys()
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
    @package.markerColour = @package.colours[0]
    @package.leader = true
    @package.leaderColour = @package.markerColour
    @package.pairingSetup()

  invite: ->
    return unless @configPresent()
    @package.generateSessionId()
    if @needsInput
      @getRecipientName @askRecipientName, => @send => @afterSend()
    else
      atom.clipboard.write(@package.sessionId)
      atom.notifications.addInfo "Your session ID has been copied to your clipboard."
      @afterSend()
