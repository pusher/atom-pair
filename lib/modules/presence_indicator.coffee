$ = require 'jquery'
_ = require 'underscore'

module.exports = PresenceIndicator =
  timeouts: []

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

  updateCollaboratorMarker: (colour, rows) ->
    @clearMarkers(colour)
    @markRows(rows, colour)

  setActiveIcon: (tab, colour)->
    $('.atom-pair-active-icon').remove()
    icon = $("<i class=\"icon icon-pencil atom-pair-active-icon\" style=\"color: #{colour}\"></i>")
    tab.itemTitle.appendChild(icon[0])
