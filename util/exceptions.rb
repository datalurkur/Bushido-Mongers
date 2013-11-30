class GameError < StandardError; end
class ParserError < StandardError; end

class AmbiguousMatchError < GameError; end
class MissingObjectExtensionError < GameError; end
class MissingProperty < GameError; end
class NoMatchError < GameError; end
class StateError < GameError; end
class UnexpectedBehaviorError < GameError; end
class UnknownType < GameError; end
class AmbiguousCommandError < GameError
  attr_reader :verb, :missing_params
  def initialize(verb, missing_params)
    @verb           = verb
    @missing_params = missing_params
    super("Missing #{missing_params.inspect} from #{verb}")
  end
end
class FailedCommandError < GameError; end
class InvalidCommandError < GameError; end
