User = require '../../lib/modules/user'
Session = require '../../lib/modules/session'
SharePane = require '../../lib/modules/share_pane'
PusherMock = require '../pusher-mock'
_ = require 'underscore'

describe "User", ->

  activationPromise = null
  pusher = null
  session = null

  beforeEach ->
    activationPromise = atom.packages.activatePackage('atom-pair')
    pusher = new PusherMock 'key', 'secret'
    spyOn(window, 'Pusher').andReturn(pusher)
    User.clear()

  afterEach ->
    session.end()
    expect(User.all.length).toEqual(0)
    expect(User.me).toBe(null)

  it 'knows the correct leader in a two person session', ->

    waitsForPromise -> activationPromise

    runs ->
      expect(User.all.length).toBe(0)

      session = new Session
      SharePane.each = ->

      spyOn(session, 'startPairing').andCallThrough()
      spyOn(session, 'resubscribe')
      spyOn(User, 'add').andCallThrough()

      me = User.addMe()
      me.arrivalTime = 1

      session.pairingSetup()
      session.channel.fakeSend('pusher:subscription_succeeded', pusher.mockMembers())
      expect(session.resubscribe).not.toHaveBeenCalled()

      session.channel.fakeSend('pusher:member_added', {
        id: 'blue',
        arrivalTime: 30
      })
      expect(User.add.calls.length).toEqual(2)
      expect(User.all.length).toBe(2)
      expect(me.isLeader()).toBe(true)
      expect(User.withColour('blue').isLeader()).toBe(false)

  it 'handles resubscription logic when !1st person', ->

    waitsForPromise -> activationPromise

    runs ->
      spyOn(window, 'Date').andReturn({getTime: -> 30})
      atom.config.set('atom-pair.pusher_app_key', 'key')
      atom.config.set('atom-pair.pusher_app_secret', 'secret')
      session = new Session
      session.pairingSetup()
      session.channel.fakeSend('pusher:subscription_succeeded', pusher.mockMembers(
        [{id: 'red', arrivalTime: 1}]
      ))

      expect(window.Pusher.argsForCall.length).toBe(2)
      expect(window.Pusher.argsForCall).toEqual([ [ 'key', { encrypted: true, authTransport : 'client', clientAuth : { key : 'key', secret : 'secret', user_id : 'blank', user_info : { arrivalTime : 'blank' } } } ], [ 'key', { encrypted: true, authTransport : 'client', clientAuth : { key : 'key', secret : 'secret', user_id : 'blue', user_info : { arrivalTime : 30 } } } ] ])
      expect(User.all.length).toBe(2)
      expect(User.me.isLeader()).toBe(false)
      expect(User.me.colour).not.toBe('red')

  it 'handles the departure of a leader correctly', ->

    waitsForPromise -> activationPromise

    runs ->

      session = new Session
      me = User.addMe()
      me.colour = 'blue'
      me.arrivalTime = 30
      session.pairingSetup()


      session.channel.fakeSend('pusher:subscription_succeeded', pusher.mockMembers(
        [{id: 'red', arrivalTime: 1}]
      ))

      session.channel.fakeSend('pusher:member_added', {
        id: 'green',
        arrivalTime: 60
      })
      spyOn(atom.notifications, 'addWarning')
      expect(User.me.isLeader()).toBe(false)
      expect(User.all.length).toEqual(3)
      expect(_.pluck(User.all, 'colour').sort()).toEqual(['blue', 'green', 'red'])

      session.channel.fakeSend('pusher:member_removed', {
        id: 'red',
        arrivalTime: 1
      })

      expect(User.all.length).toEqual(2)
      expect(User.me.isLeader()).toBe(true)
      expect(atom.notifications.addWarning).toHaveBeenCalledWith('Your pair buddy has left the session.')
