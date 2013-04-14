module Conversation
    class << self
        def listens_for(instance)
            [:unit_speaks]
        end

        def at_message(instance, message)
            return if instance.uses?(Character)
            case message.type
            when :unit_speaks
                Log.debug(["Statement received by #{instance.monicker}", message], 6)
                if message.has_param?(:receiver) && message.receiver === instance && instance.will_do_command?(message)
                    instance.perform_command(message)
                else
                    params = Words.decompose_ambiguous(message.statement)
                end
            end

            return params
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
                #say(message.agent, "Ambiguous!")
            else
                Log.debug("I don't understand: #{e.message}")
                #say(message.agent, "I don't understand: #{e.message}")
            end
            return
        end

        begin
            Commands.do(@core, command, params)
            Log.debug("#{self.monicker} did it! Yay!")
            #say(message.agent, "I did it! Yay!")
        rescue Exception => e
            Log.debug("#{self.monicker} failed because: #{e.message}")
            #say(message.agent, "I failed you because: #{e.message}")
        end
    end

    def say(receiver, statement)
        message = Message.new(:unit_speaks, {
            :agent       => self,
            :receiver    => receiver,
            :statement   => statement,
            :is_whisper  => false
        })
        locations = [self.absolute_position]
        Message.dispatch_positional(@core, locations, message.type, message.params)
        message
    end
end
