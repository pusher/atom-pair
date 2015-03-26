AtomPairView = require './atom-pair-view'

module.exports =
class AlertView extends AtomPairView

  @content: (message)->
    @div tabindex: 1, =>
      @div message
