{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class ConfigView extends View

  @content: ->
    @div =>
      @div "Enter your Pusher keys here:"
      @subview 'pusher_app_key', new TextEditorView(mini: true, placeholderText: 'Your app key')
      @subview 'pusher_app_secret', new TextEditorView(mini: true, placeholderText: 'Your app secret')
      @p 'Enter HipChat keys here to integrate (optional)'
      @subview 'hipchat_token', new TextEditorView(mini: true, placeholderText: 'Your HipChat API Access Token (admin)')
      @subview 'hipchat_room_id', new TextEditorView(mini:true, placeholderText: 'The id of the room for pairing invitations')
