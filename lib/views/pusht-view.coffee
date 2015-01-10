module.exports =
class PushtView
  constructor: (serializeState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('pusht')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The Pusht package is Alive! It's ALIVE!"
    message.classList.add('message')

    input = document.createElement('input')

    @element.appendChild(input)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
