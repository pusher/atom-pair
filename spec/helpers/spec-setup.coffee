SharePane = require '../../lib/modules/share_pane'
PusherMock = require '../pusher-mock'
MessageQueue = require '../../lib/modules/message_queue'
User = require '../../lib/modules/user'

module.exports = setup = (ctx, initialText)->
  pusher = new PusherMock 'key', 'secret'
  queue = new MessageQueue pusher
  User.addMe().colour = 'red'
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
    if initialText then ctx.buffer.setText(initialText)
