module.exports = CustomPaste =
  customPaste: ->
    text = atom.clipboard.read()
    if text.length > 800
      chunks = chunkString(text, 800)
      _.each chunks, (chunk, index) =>
        setTimeout(( =>
          atom.clipboard.write(chunk)
          @editor.pasteText()
          if index is (chunks.length - 1) then atom.clipboard.write(text)
        ), 180 * index)
    else
      @editor.pasteText()
