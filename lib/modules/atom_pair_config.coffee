_ = require 'underscore'

module.exports = AtomPairConfig =

  getKeysFromConfig: ->
    @app_key = atom.config.get('pusher_app_key') || 'd41a439c438a100756f5'
    @app_secret = atom.config.get('pusher_app_secret') || '4bf35003e819bb138249'
    @hc_key = atom.config.get 'hipchat_token'
    @room_name = atom.config.get 'hipchat_room_name'

  setConfig: ->
    @getKeysFromConfig()
    @configView = new ConfigView(@app_key, @app_secret, @hc_key, @room_name)
    @configPanel = atom.workspace.addModalPanel(item: @configView, visible: true)

    @configView.on 'core:confirm', =>
      _.each ['pusher_app_key', 'pusher_app_secret', 'hipchat_token', 'hipchat_room_name'], (key) =>
        value = @configView[key].getText()
        atom.config.set(key, value) unless value.length is 0
      @configPanel.hide()

  missingPusherKeys: ->
    _.any([@app_key, @app_secret], (key) ->
      typeof(key) is "undefined")

  missingHipChatKeys: ->
    _.any([@hc_key, @room_name], (key) ->
      typeof(key) is "undefined")
