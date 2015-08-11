SharePane = require '../../lib/modules/share_pane'
PusherMock = require '../pusher-mock'
MessageQueue = require '../../lib/modules/message_queue'

module.exports = setup = (ctx, spyQueue)->
  pusher = new PusherMock 'key', 'secret'
  queue = new MessageQueue pusher
  ctx.workspaceElement = atom.views.getView(atom.workspace)
  ctx.activationPromise = atom.packages.activatePackage('atom-pair')
  ctx.openedEditor = atom.workspace.open().then (editor) =>
    ctx.sharePane = new SharePane({
      editor: editor,
      pusher: pusher,
      sessionId: 'yolo',
      markerColour: 'red',
      id: 'a',
      queue: queue
    })
    ctx.buffer = ctx.sharePane.editor.buffer
    ctx.sharePane.setActiveIcon = ->
