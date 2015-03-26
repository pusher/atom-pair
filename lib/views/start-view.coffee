AtomPairView = require './atom-pair-view'

module.exports =
class StartView extends AtomPairView

  @content: (sessionId)->
    @div class: 'session-id', tabindex: 1, =>
      @div "Your session ID is #{sessionId}. Press cmd-c to copy to your clipboard."
