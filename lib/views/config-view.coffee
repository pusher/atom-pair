{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class ConfigView extends View

  @content: (app_key, app_secret, hc_key, room_name)->
    @div =>
      @div "Enter your Pusher keys here:"
      @small "Your app key"
      @subview 'pusher_app_key', new TextEditorView(mini: true, placeholderText: app_key)
      @small "Your app secret"
      @subview 'pusher_app_secret', new TextEditorView(mini: true, placeholderText: app_secret)
      @p 'Enter HipChat keys here to integrate (optional)'
      @small 'Your HipChat API Access Token (admin)'
      @subview 'hipchat_token', new TextEditorView(mini: true, placeholderText: hc_key)
      @small 'The name of the room for pairing invitations'
      @subview 'hipchat_room_name', new TextEditorView(mini:true, placeholderText: room_name)
