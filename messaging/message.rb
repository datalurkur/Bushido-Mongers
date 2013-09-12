require './messaging/positional_message'

require './util/opt'
Message = DEBUG ? DebugPositionalMessage : PositionalMessage
