module.exports = GrammarSync =
  syncGrammars: ->
    @editor.onDidChangeGrammar => @sendGrammar()

  sendGrammar: ->
    grammar = @editor.getGrammar()
    @queue.add(@channel.name, 'client-grammar-sync', grammar.scopeName)
