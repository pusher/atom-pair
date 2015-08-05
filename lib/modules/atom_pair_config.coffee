_ = require 'underscore'

module.exports = AtomPairConfig =

  getKeysFromConfig: ->
    @app_key = atom.config.get 'atom-pair.pusher_app_key'
    @app_secret = atom.config.get 'atom-pair.pusher_app_secret'
    @flowdock_key = atom.config.get 'atom-pair.flowdock_key'
    @hc_key = atom.config.get 'atom-pair.hipchat_token'
    @room_name = atom.config.get 'atom-pair.hipchat_room_name'
    @slack_url = atom.config.get 'atom-pair.slack_url'

  missingPusherKeys: -> _.any([@app_key, @app_secret], @missing)
  missingFlowdockKey: -> _.any([@flowdock_key], @missing)
  missingHipChatKeys: -> _.any([@hc_key, @room_name], @missing)
  missingSlackWebHook: -> _.any([@slack_url], @missing)
  missing: (key) -> key is '' || typeof(key) is "undefined"
