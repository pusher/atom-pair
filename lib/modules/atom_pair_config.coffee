_ = require 'underscore'

module.exports = AtomPairConfig =

  config:
    hipchat_token:
      type: 'string'
      description: 'HipChat admin token (optional)'
      default: ''
    hipchat_room_name:
      type: 'string'
      description: 'HipChat room name for sending invitations (optional)'
      default: ''
    pusher_app_key:
      type: 'string'
      description: 'Pusher App Key (sign up at http://pusher.com/signup and change for added security)'
      default: 'd41a439c438a100756f5'
    pusher_app_secret:
      type: 'string'
      description: 'Pusher App Secret'
      default: '4bf35003e819bb138249'
    pusher_app_id:
      type: 'string'
      description: 'Pusher App ID'
      default: '131233'
    slack_url:
      type: 'string'
      description: 'WebHook URL for Slack Incoming Webhook Integration'
      default: ''

  getKeysFromConfig: ->
    @app_key = atom.config.get 'atom-pair.pusher_app_key'
    @app_secret = atom.config.get 'atom-pair.pusher_app_secret'
    @hc_key = atom.config.get 'atom-pair.hipchat_token'
    @room_name = atom.config.get 'atom-pair.hipchat_room_name'
    @slack_url = atom.config.get 'atom-pair.slack_url'

  missingPusherKeys: -> _.any([@app_key, @app_secret], @missing)
  missingHipChatKeys: -> _.any([@hc_key, @room_name], @missing)
  missingSlackWebHook: -> _.any([@slack_url], @missing)
  missing: (key) -> key is '' || typeof(key) is "undefined"
