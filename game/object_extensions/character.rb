require './util/log'

module Character
    class << self
        def at_creation(instance, params)
            instance.set_creation_date
            instance.set_username(params[:username])
        end

        def pack(instance)
            {
                :created_on => instance.created_on,
                :username   => instance.username
            }
        end

        def unpack(core, instance, raw_data)
            [:created_on, :username].each do |key|
                raise(MissingProperty, "Character data corrupted (#{key})") unless raw_data.has_key?(key)
            end
            instance.set_creation_date(raw_data[:created_on])
            instance.set_username(raw_data[:username])
        end

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
            when :unit_acts
                # TODO - Add in distance scoping for different actions (shouting can be witnessed from further away than talking)
                if (message.agent != instance) && instance.witnesses?([instance.location])
                    instance.inform_user(message)
                end
            when :unit_speaks, :unit_whispers
                # TODO - Add in distance scoping for different actions (shouting can be witnessed from further away than talking)
                # TODO - This witnesses? check is pretty stupid: It passes in the abs_pos and then checks whether it's the abs_pos.
                if (message.agent != instance) && instance.witnesses?([instance.absolute_position])
                    if message.type == :unit_whispers && instance != message.reciever
                        # Whisper can be reported, but with no content (e.g. Bob whispers to Charlie.)
                        # TODO - Do a perception check here to see if the statement is overheard!
                        message.statement = ''
                    end

                    instance.inform_user(message)
                end
            when :unit_killed, :object_destroyed
                if instance.witnesses?([message.location])
                    instance.inform_user(message)
                end
            end
        end
    end

    attr_reader :created_on, :username

    def set_creation_date(value=nil); @created_on = value || Time.now; end
    def set_username(value); @username = value; end

    def witnesses?(locations=[], scope=:immediate)
        # FIXME - This needs to be generalized to all perceivers, not special for characters
        # TODO - Use scope to determine if events in adjacent zones can be heard / seen
        # TODO - Add perception checks
        return locations.include?(absolute_position)
    end

    def inform_user(message)
        raise(StateError, "User callback not set for #{monicker}") unless @username
        event_properties = message.params.merge(:event_type => message.type)
        @core.send_to_user(@username, Message.new(:game_event, {:description => event_properties}))
    end
end
