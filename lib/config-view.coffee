{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class ConfigView extends View

  @content: ->
    @div =>
      @div "Enter your Pusher keys here:"
      @subview 'pusher_app_key', new TextEditorView(mini: true, placeholderText: 'Your app key')
      @subview 'pusher_app_secret', new TextEditorView(mini: true, placeholderText: 'Your app secret')
