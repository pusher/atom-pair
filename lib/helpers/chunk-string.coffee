module.exports = chunkString = (str, len) ->
  _size = Math.ceil(str.length / len)
  _ret = new Array(_size)
  _offset = undefined
  _i = 0

  while _i < _size
    _offset = _i * len
    _ret[_i] = str.substring(_offset, _offset + len)
    _i++
  _ret
