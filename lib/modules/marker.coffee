$ = require 'jquery'
_ = require 'underscore'

module.exports = Marker =

  markRows: (rows, colour) ->
    _.each rows, (row) => @addMarker(row, colour)

  clearMarkers: (colour) ->
    $("atom-text-editor#AtomPair::shadow .line-number").each (index, line) =>
      $(line).removeClass(colour)

  addMarker: (line, colour) ->
    element = $("atom-text-editor#AtomPair::shadow .line-number-#{line}")
    if element.length is 0
      @timeouts.push(setTimeout((=> @addMarker(line,colour)), 50))
    else
      _.each @timeouts, (timeout) -> clearTimeout(timeout)
      element.addClass(colour)

  updateCollaboratorMarker: (data) ->
    @clearMarkers(data.colour)
    @markRows(data.rows, data.colour)
