module Conversation
    class << self
        def listens_for(instance)
            [:unit_speaks]
        end

        def at_message(instance, message)
            # Characters engage in conversation themselves.
            return     if instance.uses?(Character)
            # But other entities need perception and knowledge to talk.
            return unless instance.uses?(Perception)
            return unless instance.uses?(Knowledge)

            case message.type
            when :unit_speaks, :unit_whispers
                return unless instance == message.receiver && message.response_needed
                Log.debug(["Statement received by #{instance.monicker}: #{message.statement}"], 6)
                if message.has_param?(:receiver) && instance.will_do_command?(message)
                    instance.perform_command(message)
                else
                    params = Words.decompose_ambiguous(message.statement)
                    if params[:query]
                        return instance.answer_question(message.agent, params)
                    elsif params[:statement_path]
                        # FIXME - This should only happen if the speaker is believed.
                        # For now it is a naive world, without the considered
                        # possibility of a lie. Please don't abuse this!
                        if true # believes_statement(agent, params[:statement])
                            instance.add_knowledge_of(params[:thing])
                            instance.say(message.agent, Words.describe_knowledge(params[:statement_path]))
                        else
                            instance.say(message.agent, "I don't believe you!")
                        end
                    end
                end
            end
        end
    end

    def answer_question(asker, params)
        Log.debug("#{monicker} answering query #{params.inspect}")

        # Look up the words based on Questions::WH_MEANINGS.
        knowledge = []
        case params[:query_lookup]
        when :civil
        when :object
            # Something like an 'ask about'. We should report a random fact related to the subject.
            if self.knows_of_class?(params[:thing])
                Log.debug("#{monicker} knows of class #{params[:thing]}.", 9)
                knowledge = self.get_knowledge(params[:thing], params[:connector], params[:property])
            else
                Log.debug("#{monicker} doesn't know of class #{params[:thing]}.", 9)
                # TODO: find object by name search, search
                # self.kb.object_knowledge(thing)
            end
        when :event
        when :location
            #Find potential_locations, and answer appropriately.
        when :meaning
        when :task
            if params[:thing] == :quest
                # TODO
            elsif self.knows_of_class?(params[:thing])
                Log.debug("#{monicker} knows of class #{params[:thing]}.", 9)
                knowledge = self.get_knowledge(params[:thing], params[:connector], params[:property])
            end
        when :conditional
        else
            self.say(asker, "What a strange way to ask a question.")
            return
        end

        talk_about_knowledge(asker, knowledge)
        return params
    end


    def talk_about_knowledge(asker, knows)
        # Do final selection.
        if knows && !knows.empty?
            args = knows.rand.args

            args.merge!(:knower => self, :db => @core.db)

            self.say(asker, Words.generate(args))
        else
            self.say(asker, "I don't know anything about that.")
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
        Log.debug("#{self.monicker} says, \"#{statement}\"")
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
        Log.debug("#{self.monicker} whispers, \"#{statement}\"")
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
