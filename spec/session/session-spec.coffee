Session = require '../../lib/modules/session'
Invitation = require '../../lib/modules/invitations/invitation'
PusherMock = require '../pusher-mock'
User = require '../../lib/modules/user'
SharePane = require '../../lib/modules/share_pane'
PresenceIndicator = require '../../lib/modules/presence_indicator'
_ = require 'underscore'

describe 'Session', ->

  User.prototype.updatePosition =->

  activationPromise = null
  pusher = null

  beforeEach ->
    activationPromise = atom.packages.activatePackage('atom-pair')
    pusher = new PusherMock
    spyOn(window, 'Pusher').andReturn(pusher)
    atom.config.set("atom_pair.pusher_app_key", "key")
    atom.config.set("atom_pair.pusher_app_secret","secret")

  it 'complains if joining when already in an active session', ->
    waitsForPromise -> activationPromise

    runs ->
      spyOn(atom.notifications, 'addError')
      session = new Session
      Session.active = session
      Session.join()
      expect(atom.notifications.addError).toHaveBeenCalledWith("It looks like you are already in a pairing session. Please open a new window (cmd+shift+N) to start/join a new one.")

  it 'can be created from an ID', ->
    waitsForPromise -> activationPromise

    runs ->
      session = Session.fromID("key-secret-randomstring")
      expect(session.id).toEqual("key-secret-randomstring")
      expect(session.app_key).toEqual("key")
      expect(session.app_secret).toEqual("secret")

  describe 'panesync', ->

    setUpSession = ->
      atom.config.set('atom-pair.pusher_app_key', 'key')
      atom.config.set('atom-pair.pusher_app_secret', 'secret')
      session = new Session
      new Invitation(session)
      session.channel.fakeSend('pusher:subscription_succeeded', pusher.mockMembers())
      session

    it 'syncs over existing panes', ->
      waitsForPromise -> activationPromise
      openOneEditor = atom.workspace.open().then (editor1)->
        editor1.buffer.setText("hello world")
      openSecondEditor = atom.workspace.open().then (editor2) ->
        editor2.buffer.setText("waddup")
      waitsForPromise -> openOneEditor
      waitsForPromise -> openSecondEditor

      runs ->
        session = setUpSession()
        spyOn(session.queue, 'add')
        expect(SharePane.all.length).toEqual(2)
        expect(session.active).toBe(true)
        expect(User.me.isLeader()).toBe(true)

        # when new person is added
        session.channel.fakeSend('pusher:member_added', {
            id: 'blue',
            arrivalTime: new Date().getTime()
        })

        firstCall = session.queue.add.argsForCall[0]
        secondCall = session.queue.add.argsForCall[1]

        expect(firstCall[1]).toEqual('client-please-make-a-share-pane')
        expect(secondCall[1]).toEqual('client-please-make-a-share-pane')
        expect(firstCall[2].from).toEqual('red')
        expect(secondCall[2].from).toEqual('red')
        expect(firstCall[2].to).toEqual('blue')
        expect(secondCall[2].to).toEqual('blue')
        expect(firstCall[2].paneId).not.toEqual(secondCall.paneId)

        # sending over files
        SharePane.each (pane) ->
          spyOn(pane, 'shareFile')
          spyOn(pane, 'sendGrammar')
          session.channel.fakeSend('client-i-made-a-share-pane', {
              paneId: pane.id,
              to: 'red'
          })
          expect(pane.shareFile).toHaveBeenCalled()
          expect(pane.sendGrammar).toHaveBeenCalled()
        _.each atom.workspace.getPaneItems(), (pane) -> pane.destroy()
        SharePane.clear()

    it 'creates new tabs on receipt of please-make-a-sharepane event', ->
      waitsForPromise -> activationPromise
      newEditor = null
      session = null
      runs ->
        Session.prototype.shareOpenPanes = ->
        SharePane.prototype.setTabTitle =->
        session = setUpSession()
        expect(session.active).toBe(true)
        expect(atom.workspace.getTextEditors().length).toEqual(0)
        expect(atom.workspace.getActiveTextEditor()).toBe(undefined)
        spyOn(session, 'createSharePane').andCallThrough()
        spyOn(session.queue, 'add')
        session.channel.fakeSend('client-please-make-a-share-pane', {
            to: User.me.colour,
            from: 'blue'
            paneId: 'hello',
            title: 'untitled'
        })

        atom.workspace.onDidOpen ({item})-> newEditor = item
      waitsFor -> !!newEditor
      runs ->
        expect(session.queue.add.argsForCall).toEqual([ [ 'test-channel', 'client-i-made-a-share-pane', { to : 'blue', paneId : 'hello' } ] ])
        expect(session.createSharePane.argsForCall).toEqual([[newEditor, 'hello', 'untitled']])
        expect(atom.workspace.getTextEditors().length).toEqual(1)
        expect(SharePane.all.length).toEqual(1)
        expect(SharePane.all[0].id).toEqual('hello')
        SharePane.clear()

    it 'syncs newly opened panes', ->
      waitsForPromise -> activationPromise
      waitsForPromise ->
        atom.packages.activatePackage('language-ruby')

      newEditor = null
      session = null
      runs ->
        session = setUpSession()

        spyOn(session.queue, 'add')
        newEditor = atom.workspace.open('../fixtures/basic-buffer-write.json').then (editor)->

      waitsForPromise -> newEditor
      runs ->
        pane = SharePane.all[0]
        expect(session.queue.add.argsForCall).toEqual([
          ['test-channel',
           'client-please-make-a-share-pane', {
             to: 'all',
             from: 'red',
             paneId: pane.id,
             title: 'basic-buffer-write.json'
           }
          ]
        ])
        spyOn(pane, 'shareFile')
        spyOn(pane, 'sendGrammar')
        session.channel.fakeSend('client-i-made-a-share-pane', {
            to: User.me.colour,
            paneId: pane.id
        })
        expect(pane.shareFile).toHaveBeenCalled()
        expect(pane.sendGrammar).toHaveBeenCalled()
        SharePane.clear()

  describe 'disconnection', ->

    it 'resets state on disconnect',->
      newEditor = null
      session = null
      waitsFor -> activationPromise

      runs ->
        atom.config.set('atom-pair.pusher_app_key', 'key')
        atom.config.set('atom-pair.pusher_app_secret', 'secret')
        session = new Session
        new Invitation(session)
        session.channel.fakeSend('pusher:subscription_succeeded', pusher.mockMembers([
            {id: 'blue', arrivalTime: 1}
        ]))
        session.channel.fakeSend('client-please-make-a-share-pane', {
            to: User.me.colour,
            from: 'blue'
            paneId: 'hello',
            title: 'untitled'
        })

        atom.workspace.onDidOpen ({item})-> newEditor = item

      waitsFor -> !!newEditor
      runs ->
        expect(User.all.length).toEqual(2)
        expect(SharePane.all.length).toEqual(1)
        spyOn(session.queue, 'dispose')
        session.end()
        expect(pusher.connected).toBe(false)
        expect(User.all.length).toBe(0)
        expect(User.me).toBe(null)
        expect(SharePane.all.length).toBe(0)
        expect(session.subscriptions.disposed).toBe(true)
        expect(session.queue.dispose).toHaveBeenCalled()
        expect(session.id).toBe(null)
        expect(Session.active).toBe(null)
        expect(session.active).toBe(false)
