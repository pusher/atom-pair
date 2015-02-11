_ = require 'underscore'
ConfigView = require '../views/config-view'

module.exports = AtomPairConfig =

  getKeysFromConfig: ->
    @app_key = atom.config.get 'atom-pair.pusher_app_key'
    @app_secret = atom.config.get 'atom-pair.pusher_app_secret'
    @hc_key = atom.config.get 'atom-pair.hipchat_token'
    @room_name = atom.config.get 'atom-pair.hipchat_room_name'

  setConfig: ->
    @getKeysFromConfig()
    @configView = new ConfigView(@app_key, @app_secret, @hc_key, @room_name)
    @configPanel = atom.workspace.addModalPanel(item: @configView, visible: true)

    @configView.on 'core:confirm', =>
      _.each ['pusher_app_key', 'pusher_app_secret', 'hipchat_token', 'hipchat_room_name'], (key) =>
        value = @configView[key].getText()
        atom.config.set("atom-pair.#{key}", value) unless value.length is 0
      @configPanel.hide()

  missingPusherKeys: ->
    _.any([@app_key, @app_secret], @missing)

  missing: (key)->
    key is '' || typeof(key) is "undefined"

  missingHipChatKeys: ->
    _.any([@hc_key, @room_name], @missing)
