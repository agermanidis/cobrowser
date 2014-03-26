require './meta'

refresh = (coll, obj) ->
  obj.collection = coll
  for member, index in coll
    obj[index] = member
  index = coll.length
  while obj[index]
    delete obj[index++]

class FileList
  item: (index) ->
    @collection[index] or null

  @get length: -> @collection.length

  constructor: (coll = []) ->
    refresh coll, @

class Blob
  @readonly ['size']
  constructor: (@_data) ->

class File extends Blob


module.exports = {FileList, Blob, File}
