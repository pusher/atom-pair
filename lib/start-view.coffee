{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class StartView extends View

  @content: (sessionId)->
    @div =>
      @div "Your session ID is #{sessionId}. Press cmd-c to copy to your clipboard"
