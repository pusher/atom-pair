module.exports = GrammarSync =
  syncGrammars: ->
    @editor.onDidChangeGrammar => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @channel.trigger 'client-grammar-sync', grammar.scopeName
