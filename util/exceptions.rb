class GameError < StandardError; end
class ParserError < StandardError; end

class AmbiguousMatchError < GameError; end
class InvalidCommandError < GameError; end
class MissingObjectExtensionError < GameError; end
class MissingProperty < GameError; end
class NoMatchError < GameError; end
class StateError < GameError; end
class UnexpectedBehaviorError < GameError; end
class UnknownType < GameError; end
class FailedCommandError < GameError; end
