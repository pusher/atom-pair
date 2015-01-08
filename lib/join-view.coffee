{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class JoinView extends View

  @content: ->
    @div =>
      @div "Enter the session ID here:"
      @subview 'sessionId', new TextEditorView(mini: true)
