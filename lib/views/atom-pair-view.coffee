{View} = require 'space-pen'
_ = require 'underscore'

module.exports =
  class AtomPairView extends View

    initialize: ->
      @panel ?= atom.workspace.addModalPanel(item: @, visible: true)
      @.focus()
      @.on 'core:cancel', => @hideView()

    hideView: ->
      @panel.hide()
      @.focusout()
