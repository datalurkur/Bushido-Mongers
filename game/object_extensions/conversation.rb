module Conversation
    class << self
        def listens_for(instance)
            [:unit_speaks]
        end

        def at_message(instance, message)
            return     if instance.uses?(Character)
            return unless instance.uses?(Perception)

            case message.type
            when :unit_speaks, :unit_whispers
                return unless message.response_needed
                Log.debug(["Statement received by #{instance.monicker}", message], 4)
                if message.has_param?(:receiver) && message.receiver === instance && instance.will_do_command?(message)
                    instance.perform_command(message)
                else
                    params = Words.decompose_ambiguous(message.statement)
                    if params[:query]
                        query_path = []
                        # Look up the words based on Questions::WH_MEANINGS.
                        case params[:query_class]
                        when :civil
                            params[:query]
                        when :object
                        when :event
                        when :location
                            # FIXME - Can only ask the location of things in the
                            # same room ATM. Kind of pointless, really.
                            query_path << :location
                            #query_path << filter_objects(:position, stuff)
                        when :meaning
                        when :skill
                        else
                            # Something like an 'ask about'. We should report a random fact related to the subject.
                            instance.say(message.agent, "I don't know how to decide what to tell you about that.")
                            return
                        end

                        knowledge = instance.get_knowledge_of(query_path)
                        if knowledge
                            instance.say(message.agent, Words.describe_knowledge(knowledge))
                        else
                            instance.say(message.agent, "I don't know anything about that.")
                        end
                    elsif params[:statement_path]
                        # FIXME - This should only happen if the speaker is believed.
                        # For now it is a naive world, without the considered
                        # possibility of a lie. Please don't abuse this!
                        if true # believes_statement(agent, params[:statement_path])
                            instance.add_knowledge_of(params[:statement_path])
                            instance.say(message.agent, Words.describe_knowledge(params[:statement_path]))
                        else
                            instance.say(message.agent, "I don't believe you!")
                        end
                    end
                end
            end
        end
    end

    # Eventually this method will be more extensive, deciding based on the status of the requester.
    def will_do_command?(message)
        # For now, just verify that it's a command.
        @core.db.static_types_of(:command).include?(message.statement.first)
    end

    def perform_command(message)
        params = Words.decompose_command(message.statement.map(&:to_s).join(" "))
        command = params[:command]
        Log.debug(params)

        begin
            Log.debug("#{self.monicker} performing command #{command}", 8)
            params = Commands.stage(@core, command, params.merge(:agent => self))
        rescue Exception => e
            Log.debug(["Failed to stage command #{command}", e.message, e.backtrace])
            if AmbiguousCommandError === e
                Log.debug("Ambiguous!")
                say(message.agent, "Ambiguous!")
            else
                Log.debug("I don't understand: #{e.message}")
                say(message.agent, "I don't understand: #{e.message}")
            end
            return
        end

        begin
            Commands.do(@core, command, params)
            Log.debug("#{self.monicker} did it! Yay!")
            say(message.agent, "I did it! Yay!")
        rescue Exception => e
            Log.debug("#{self.monicker} failed because: #{e.message}")
            say(message.agent, "I failed you because: #{e.message}")
        end
    end

#private
    def say(receiver, statement, response_needed = false)
        message = Message.new(:unit_speaks, {
            :agent           => self,
            :receiver        => receiver,
            :statement       => statement,
            :response_needed => response_needed
        })
        locations = [self.absolute_position]
        Message.dispatch_positional(@core, locations, message.type, message.params)
        message
    end

    def whisper(receiver, statement, response_needed = false)
        message = Message.new(:unit_whispers, {
            :agent           => self,
            :receiver        => receiver,
            :statement       => statement,
            :response_needed => response_needed
        })
        locations = [self.absolute_position]
        Message.dispatch_positional(@core, locations, message.type, message.params)
        message
    end
end
