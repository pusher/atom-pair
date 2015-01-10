{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class InputView extends View

  @content: (label)->
    @div =>
      @div label
      @subview 'miniEditor', new TextEditorView(mini: true)
