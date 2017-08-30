SharePane = require '../../lib/modules/share_pane'
Session = require '../../lib/modules/session'
Invitation = require '../../lib/modules/invitations/invitation'
PusherMock = require '../pusher-mock'
MessageQueue = require '../../lib/modules/message_queue'
User = require '../../lib/modules/user'
_ = require 'underscore'

describe 'SharePane:disconnect',->

  activationPromise = null
  pusher = null

  setUpSession = ->
    session = Session.initiate(Invitation)
    session.channel.fakeSend(
      'pusher:subscription_succeeded',
      pusher.mockMembers()
    )
    session

  beforeEach ->
    atom.config.set('atom-pair.pusher_app_key', 'key')
    atom.config.set('atom-pair.pusher_app_secret', 'secret')
    activationPromise = atom.packages.activatePackage('atom-pair')
    pusher = new PusherMock 'key', 'secret'
    spyOn(window, 'Pusher').andReturn(pusher)

  it 'cleans up state upon disconnect', ->
    waitsForPromise -> activationPromise
    openedEditor = null
    runs ->
      session = setUpSession()
      openedEditor = atom.workspace.open()

    waitsForPromise -> openedEditor
    runs ->
      expect(SharePane.all.length).toEqual(1)
      sharePane = SharePane.all[0]
      expect(sharePane.editorListeners.disposed).toBe(false)
      expect(sharePane.buffer).toBeDefined()
      expect(SharePane.globalEmitter.disposed).toBe(false)
      sharePane.disconnect()
      expect(SharePane.all.length).toEqual(0)
      expect(sharePane.editorListeners.disposed).toBe(true)
      expect(sharePane.buffer).toBe(null)
      expect(SharePane.globalEmitter.disposed).toBe(true)

  it 'closes the session if all sharepanes have been destroyed', ->
    waitsForPromise -> activationPromise
    openedEditor1 = null
    openedEditor2 = null
    session = null
    runs ->
      session = setUpSession()
      openedEditor1 = atom.workspace.open()
      openedEditor2 = atom.workspace.open()

    waitsForPromise -> openedEditor1
    waitsForPromise -> openedEditor2
    runs ->
      spyOn(session, 'end')
      expect(SharePane.all.length).toBe(2)
      SharePane.each (pane) ->
        pane.disconnect()
      expect(session.end).toHaveBeenCalled()
