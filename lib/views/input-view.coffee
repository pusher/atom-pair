AtomPairView = require './atom-pair-view'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class InputView extends AtomPairView

  @content: (label)->
    @div =>
      @span click: 'hideView', class: 'atom-pair-exit-view', "X"
      @div label
      @subview 'miniEditor', new TextEditorView(mini: true)

  onInput: (fn)->
    @miniEditor.focus()
    atom.commands.add @element, 'core:confirm': =>
      @panel.hide()
      fn(@miniEditor.getText())
