$ = require 'jquery'
_ = require 'underscore'

module.exports = Marker =

  assignColour: (takenColour) ->
    colour = _.sample(@colours)
    if colour is takenColour then @assignColour()

    data = {colour: takenColour}
    @receiveFriendInfo(data)
    @markerColour = colour

  receiveFriendInfo: (data) ->
    friendInfo = {colour: data.colour}
    unless _.contains(@friendColours, friendInfo.colour)
      @friendColours.push(data.colour)
    unless friendInfo.markerSeen
      @addMarker 0, data.colour
      friendInfo.markerSeen = true

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
