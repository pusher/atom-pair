module.exports = GrammarSync =
  syncGrammars: ->
    @editor.on 'grammar-changed', => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @pairingChannel.trigger 'client-grammar-sync', grammar.scopeName
