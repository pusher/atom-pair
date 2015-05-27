{View} = require 'space-pen'
_ = require 'underscore'

module.exports =
  class AtomPairView extends View

    initialize: ->
      @panel ?= atom.workspace.addModalPanel(item: @, visible: true)
      @.focus()
      atom.commands.add(@element, 'core:cancel', => @hideView())

    hideView: ->
      @panel.hide()
      @.focusout()
