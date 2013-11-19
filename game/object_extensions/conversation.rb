module Conversation
    class << self
        def listens_for(instance)
            [:unit_speaks, :unit_whispers]
        end

        def at_message(instance, message)
            return unless listens_for(instance).include?(message.type)
            Log.debug(["Message #{message.type} received by #{instance.monicker}"], 1)
            # Characters engage in conversation themselves.
            return     if instance.uses?(Character)
            # But other entities need perception and knowledge to talk.
            return unless instance.uses?(Perception)
            return unless instance.uses?(Knowledge)

            # Statement is an array of symbols
            statement_s = message.statement.map(&:to_s).join(" ")

            Log.debug(["Message received by #{instance.monicker}: #{statement_s}"], 1)
            return unless instance == message.receiver && message.response_needed
            Log.debug(["Response needed from #{instance.monicker} to #{statement_s}"], 6)

            if instance.will_do_command?(message)
                return instance.perform_command(message)
            else
                params = instance.decompose_ambiguous(message.statement)
                if params[:query]
                    instance.answer_question(message.agent, params)
                elsif params[:statement]
                    # FIXME - This should only happen if the speaker is believed.
                    # For now it is a naive world, without the considered
                    # possibility of a lie. Please don't abuse this!
                    if true # believes_statement(agent, params[:statement])
                        instance.add_knowledge_of(params[:thing])
                        instance.say(message.agent, @core.words_db.describe_knowledge(params[:statement]))
                    else
                        instance.say(message.agent, "I don't believe you!")
                    end
                else
                    instance.say(message.agent, "I don't understand.")
                end
                return params
            end
        end
    end

    def decompose_ambiguous(statement); @core.words_db.decompose_ambiguous(statement); end

    def answer_question(asker, params)
        Log.debug("#{monicker} answering query #{params.inspect}")

        # Look up the words based on Questions::WH_MEANINGS.
        knowledge = []
        case params[:query_lookup]
        when :civil
            self.say(asker, "I don't know how to answer that question.")
        when :object
            # Something like an 'ask about': report a random fact related to the subject.
            if self.knows_of_class?(params[:thing])
                Log.debug("#{monicker} knows of class #{params[:thing]}.", 9)
                knowledge = self.get_knowledge(params[:thing], params[:connector], params[:property])
            else
                # TODO: Narrow down the thing further.
                Log.debug(params)
                thing = params[:thing]
                thing = self if thing == :self
                knowledge = self.get_knowledge(thing, params[:connector], params[:property])
            end
        when :event
        when :location
            # Search potential_locations, and answer appropriately.
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

            args.merge!(:observer => self, :speaker => self, :db => @core.db)

            # Make sure there aren't any BOs passed to Words.
            args.each do |k, v|
                args[k] = Descriptor.describe(v, self) if v.is_a?(BushidoObject)
            end

            self.say(asker, @core.words_db.generate(args))
        else
            self.say(asker, "I don't know anything about that.")
        end
    end

    # Eventually this method will be more extensive, deciding based on the status of the requester.
    def will_do_command?(message)
        # For now, just verify that it's a command.
        return false if message.statement.first.nil?
        @core.db.static_types_of(:command).include?(message.statement.first)
    end

    def perform_command(message)
        params = @core.words_db.decompose_command(message.statement.map(&:to_s).join(" "))
        command = params[:command]
        Log.debug(params)

        begin
            Log.debug("#{self.monicker} performing command #{command}", 8)
            params = Commands.stage(@core, command, params.merge(:agent => self))
        rescue Exception => e
            Log.debug(["Failed to stage command #{command}", e.message, e.backtrace])
            if AmbiguousCommandError === e
                say(message.agent, "Ambiguous!")
            else
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
        params
    end

#private
    def say(receiver, statement, response_needed = false)
        Log.debug("#{self.monicker} says, #{statement.inspect} to #{receiver.monicker}#{response_needed ? ", wanting a response" : ""}")
        if statement.is_a?(String)
            statement = statement.split(/\s/).map(&:to_sym)
        end
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

    # TODO: Some sort of perception check to determine whether the message is received.
    def whisper(receiver, statement, response_needed = false)
        Log.debug("#{self.monicker} whispers, #{statement.inspect} to #{receiver.monicker}#{response_needed ? ", wanting a response" : ""}")
        if statement.is_a?(String)
            statement = statement.split(/\s/).map(&:to_sym)
        end
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
