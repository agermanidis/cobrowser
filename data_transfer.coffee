require './dom/meta'

class DataTransfer
  @readonly ['dropEffect', 'effectAllowed']

  @get files: ->

class DataTransferItemList

class DataTransferItem
  @readonly ['kind', 'type']

  getAsString: (cb) ->
    return unless cb

  getAsFile: ->

  constructor: (@_data) ->

module.exports = {DataTransfer, DataTransferItemList, DataTransferItem}
