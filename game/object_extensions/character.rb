require './util/log'

module Character
    class << self
        def listens_for(i); [:core]; end

        def at_message(instance, message)
            case message.type
            when :unit_moves
                if (message.agent != instance) && instance.witnesses?([message.origin, message.destination])
                    instance.inform_user(message)
                end
            when :unit_attacks
                locations = [message.attacker.absolute_position, message.defender.absolute_position]
                # Make sure the user sees the attack if they're the target, even if the attacker is hidden
                if (message.attacker == instance) || (message.defender == instance) || instance.witnesses?(locations)
                    instance.inform_user(message)
                end
            when :unit_acts, :unit_speaks, :unit_whispers
                # TODO - Add in distance scoping for different actions (shouting can be witnessed from further away than talking)
                if (message.agent != instance) && instance.witnesses?([message.location])
                    instance.inform_user(message)
                end
            when :unit_killed, :object_destroyed
                if instance.witnesses?([message.location])
                    instance.inform_user(message)
                end
            end
        end
    end

    def witnesses?(locations=[], scope=:immediate)
        # FIXME - This needs to be generalized to all perceivers, not special for characters
        # TODO - Use scope to determine if events in adjacent zones can be heard / seen
        # TODO - Add perception checks
        return locations.include?(absolute_position)
    end

    def set_user_callback(lobby, username)
        Log.debug("Setting user callback for #{monicker}")
        @lobby    = lobby
        @username = username
    end

    def inform_user(message)
        raise(StateError, "User callback not set for #{monicker}") unless @lobby
        event_properties = message.params.merge(:event_type => message.type)
        @lobby.send_to_user(@username, Message.new(:game_event, {:description => event_properties}))
    end
end
