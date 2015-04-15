AtomPairView = require './atom-pair-view'

module.exports =
class AlertView extends AtomPairView

  @content: (message)->
    @div tabindex: 1, =>
      @span click: 'hideView', class: 'atom-pair-exit-view', "X"
      @div message
