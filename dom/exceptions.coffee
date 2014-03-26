INDEX_SIZE_ERR = 1
DOMSTRING_SIZE_ERR = 2
HIERARCHY_REQUEST_ERR = 3
WRONG_DOCUMENT_ERR = 4
INVALID_CHARACTER_ERR = 5
NO_MODIFICATION_ALLOWED_ERR = 7
NOT_FOUND_ERR = 8
NOT_SUPPORTED_ERR = 9
INVALID_STATE_ERR = 11
SYNTAX_ERR = 12
INVALID_MODIFICATION_ERR = 13
NAMESPACE_ERR = 14
INVALID_ACCESS_ERR = 15
TYPE_MISMATCH_ERR = 17
SECURITY_ERR = 18
NETWORK_ERR = 19
ABORT_ERR = 20
URL_MISMATCH_ERR = 21
QUOTA_EXCEEDED_ERR = 22
TIMEOUT_ERR = 23
INVALID_NODE_TYPE_ERR = 24
DATA_CLONE_ERR = 25

names =
  1: "Index Size Error"
  2: "Domstring Size Error"
  3: "Hierarchy Request Error"
  4: "Wrong Document Error"
  5: "Invalid Character Error"
  7: "No Modification Allowed Error"
  8: "Not Found Error"
  9: "Not Supported Error"
  11: "Invalid State Error"
  12: "Syntax Error"
  13: "Invalid Modification Error"
  14: "Namespace Error"
  15: "Invalid Access Error"
  17: "Type Mismatch Error"
  18: "Security Error"
  19: "Network Error"
  20: "Abort Error"
  21: "URL Mismatch Error"
  22: "Quota Exceeded Error"
  23: "Timeout Error"
  24: "Invalid Node Error"
  25: "Data Clone Error"

class DOMException extends Error
  constructor: (@code, @message) ->
    @name = names[@code]

module.exports = {DOMException, INDEX_SIZE_ERR, HIERARCHY_REQUEST_ERR, DOMSTRING_SIZE_ERR, WRONG_DOCUMENT_ERR, INVALID_CHARACTER_ERR, NO_MODIFICATION_ALLOWED_ERR, NOT_FOUND_ERR, NOT_SUPPORTED_ERR, INVALID_STATE_ERR, SYNTAX_ERR, INVALID_MODIFICATION_ERR, NAMESPACE_ERR, INVALID_ACCESS_ERR, TYPE_MISMATCH_ERR, SECURITY_ERR, NETWORK_ERR, ABORT_ERR, URL_MISMATCH_ERR, QUOTA_EXCEEDED_ERR, TIMEOUT_ERR, INVALID_NODE_TYPE_ERR, DATA_CLONE_ERR}

