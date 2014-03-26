parseListOfDimensions = (rawInput) ->
  if endsWith rawInput, ','
    rawInput = rawInput.substring 0, rawInput.length - 1

  result = []
  rawTokens = rawInput.split ','

  for token in rawTokens
    position = 0
    value = 0

  result

