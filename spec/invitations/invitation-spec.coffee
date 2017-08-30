Invitation = require '../../lib/modules/invitations/invitation'
HipChatInvitation = require '../../lib/modules/invitations/hipchat_invitation'
SlackInvitation = require '../../lib/modules/invitations/slack_invitation'
Session = require '../../lib/modules/session'
PusherMock = require '../pusher-mock'
User = require '../../lib/modules/user'

describe 'Invitation', ->

  activationPromise = null

  beforeEach ->
    activationPromise = atom.packages.activatePackage('atom-pair')
    pusher = new PusherMock
    spyOn(window, 'Pusher').andReturn(pusher)

  it 'complains if there are no Pusher keys', ->
    waitsForPromise -> activationPromise
    runs ->
      atom.config.set('atom-pair.pusher_app_key', '')
      atom.config.set('atom-pair.pusher_app_secret', '')
      session = new Session
      spyOn(atom.notifications, 'addError')
      invitation = new Invitation(session)
      expect(atom.notifications.addError).toHaveBeenCalled()

  it 'writes a session ID to clipboard and sets up session', ->
    waitsForPromise -> activationPromise
    runs ->
      session = new Session
      atom.config.set('atom-pair.pusher_app_key', 'key')
      atom.config.set('atom-pair.pusher_app_secret', 'secret')
      spyOn(atom.clipboard, 'write')
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addInfo')
      spyOn(session, 'pairingSetup')
      session.id = 'lala'
      invitation = new Invitation(session)
      expect(atom.notifications.addError).not.toHaveBeenCalled()
      expect(atom.clipboard.write).toHaveBeenCalledWith('lala')
      expect(atom.notifications.addInfo).toHaveBeenCalled()
      expect(User.me).toBeDefined()
      expect(session.pairingSetup).toHaveBeenCalled()

  it 'allows you to invite to an already active session', ->
    waitsForPromise -> activationPromise

    runs ->
      atom.config.set('atom-pair.pusher_app_key', 'key')
      atom.config.set('atom-pair.pusher_app_secret', 'secret')
      session = new Session
      session.id = "my_session_id"
      Session.active = session
      spyOn(atom.clipboard, 'write')
      Session.initiate(Invitation)
      expect(atom.clipboard.write).toHaveBeenCalledWith('my_session_id')



  describe 'SlackInvitation', ->

    it 'complains if there is no slack webhook url', ->
      waitsForPromise -> activationPromise

      runs ->
        session = new Session
        atom.config.set('atom-pair.pusher_app_key', 'key')
        atom.config.set('atom-pair.pusher_app_secret', 'secret')
        spyOn(atom.notifications, 'addError')
        invitation = new SlackInvitation(session)
        expect(atom.notifications.addError).toHaveBeenCalledWith("Please set your Slack Incoming WebHook")

    it 'sends the slack webhook', ->
      waitsForPromise -> activationPromise

      runs ->
        mockSlack = {
          setWebhook: ->
          webhook: (params, done) ->
            done()
        }
        spyOn(SlackInvitation.prototype, 'getSlack').andReturn(mockSlack)
        spyOn(SlackInvitation.prototype, 'afterSend')
        SlackInvitation.prototype.getRecipientName = (cta, callback) ->
          callback()

        spyOn(mockSlack, 'setWebhook')
        spyOn(mockSlack, 'webhook').andCallThrough()
        spyOn(atom.notifications, 'addInfo')
        atom.config.set('atom-pair.pusher_app_key', 'key')
        atom.config.set('atom-pair.pusher_app_secret', 'secret')
        atom.config.set('atom-pair.slack_url', 'yolo.com')
        session = new Session
        invitation = new SlackInvitation(session)
        expect(mockSlack.setWebhook).toHaveBeenCalledWith('yolo.com')
        expect(mockSlack.webhook).toHaveBeenCalled()
        expect(atom.notifications.addInfo).toHaveBeenCalled()
        expect(SlackInvitation.prototype.afterSend).toHaveBeenCalled()

    describe 'HipChat invitation', ->

      it 'complains if there is no token', ->
        waitsForPromise -> activationPromise

        runs ->
          session = new Session
          atom.config.set('atom-pair.pusher_app_key', 'key')
          atom.config.set('atom-pair.pusher_app_secret', 'secret')
          spyOn(atom.notifications, 'addError')
          invitation = new HipChatInvitation(session)
          expect(atom.notifications.addError).toHaveBeenCalledWith("Please set your HipChat keys.")

      it 'sends the hipchat invitation', ->
        waitsForPromise -> activationPromise

        runs ->
          mockRoom = 'room'
          mockHipChat = {
            listRooms: (done) -> done(rooms: [{name:mockRoom, room_id: 1}])
            postMessage: (params, done) ->
              done()
          }
          spyOn(HipChatInvitation.prototype, 'getHipChat').andReturn(mockHipChat)
          spyOn(HipChatInvitation.prototype, 'afterSend')
          HipChatInvitation.prototype.getRecipientName = (cta, callback) ->
            @recipient = "@jam"
            callback()

          spyOn(atom.notifications, 'addInfo')
          spyOn(atom.notifications, 'addError')
          spyOn(mockHipChat, 'postMessage').andCallThrough()
          atom.config.set('atom-pair.pusher_app_key', 'key')
          atom.config.set('atom-pair.pusher_app_secret', 'secret')
          atom.config.set('atom-pair.hipchat_room_name', mockRoom)
          atom.config.set('atom-pair.hipchat_token', 'token')
          session = new Session
          invitation = new HipChatInvitation(session)
          expect(atom.notifications.addError).not.toHaveBeenCalled()
          expect(mockHipChat.postMessage).toHaveBeenCalled()
          expect(atom.notifications.addInfo).toHaveBeenCalled()
          expect(HipChatInvitation.prototype.afterSend).toHaveBeenCalled()
