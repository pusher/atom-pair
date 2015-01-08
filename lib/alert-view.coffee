{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class AlertView extends View

  @content: ->
    @div =>
      @div "Please set your Pusher keys."
