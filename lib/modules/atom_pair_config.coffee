_ = require 'underscore'

module.exports = AtomPairConfig =

  getKeysFromConfig: ->
    @app_key = atom.config.get 'atom-pair.pusher_app_key'
    @app_secret = atom.config.get 'atom-pair.pusher_app_secret'
    @hc_key = atom.config.get 'atom-pair.hipchat_token'
    @room_name = atom.config.get 'atom-pair.hipchat_room_name'

  missingPusherKeys: -> _.any([@app_key, @app_secret], @missing)
  missingHipChatKeys: -> _.any([@hc_key, @room_name], @missing)
  missing: (key) -> key is '' || typeof(key) is "undefined"
