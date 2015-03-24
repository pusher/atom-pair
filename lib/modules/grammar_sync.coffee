module.exports = GrammarSync =
  syncGrammars: ->
    @editor.onDidChangeGrammar => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @pairingChannel.trigger 'client-grammar-sync', grammar.scopeName
