module Quest
    class << self
        # For pack and unpack, we need a way to reference BushidoObjects uniquely without a pointer (basically, a unique ID) so that they can be unliked but still reconstructable
        def pack(instance)
            raise(NotImplementedException)
        end

        def unpack(core, instance, raw_data)
            raise(NotImplementedException)
        end

        def at_creation(instance, params)
            Log.debug([instance, params])
            instance.create_quest(params)
        end

        def at_message(instance, message)
            return unless instance.pertinent_event_types.include?(message.type)
            Log.debug("quest checking #{message.type}")
            instance.fail_conditions.each do |condition|
                if condition_met?(condition, message)
                    instance.fail_quest(condition)
                    return
                end
            end
            instance.success_conditions.each do |condition|
                if condition_met?(condition, message)
                    instance.succeed_quest
                    return
                end
            end
        end

        def condition_met?(condition, message)
            relevant_keys = condition.keys - [:message, :condition]
            return false if condition[:message] && (condition[:message] != message.type)
            Log.debug(["Relevant keys", relevant_keys])
            relevant_keys.each do |k|
                match = case condition[k]
                when Symbol
                    message[k].matches(:type => condition[k]) || message[k].matches(:name => condition[k])
                when BushidoObjectBase
                    condition[k].uid == message.send(k).uid
                end
                return false unless match
            end
            if condition[:condition].is_a?(Proc)
                return false unless condition[:condition].call(message)
            end
            return true
        end

        # Basic quest stubs here

        # Basic object delivery quest
        def object_delivery_quest(object, receiver)
            {
                :success_conditions => [{:message => :object_given, :target => object, :receiver => receiver}],
                :rewards => [{:type => :object, :count => 100, :object => :coin}],
                :failure_conditions => [{:message => :object_destroyed, :target => object}],
                # FIXME - faction => receiver.faction
                :penalty => {:type => :good_deed, :faction => nil, :magnitude => :minor }
            }
        end
    end

    attr_reader :fail_conditions, :success_conditions, :pertinent_event_types

    # Start listening for success / fail
    def create_quest(params)
        @success_conditions = params[:success_conditions]
        raise MissingProperty, "No way to finish quest!" unless @success_conditions
        @fail_conditions    = params[:failure_conditions]
        @rewards = params[:rewards]
        @penalty = params[:penalty]

        @state   = :created

        # When we're all done, start listening for victory / failure messages/conditions
        all_conditions = (@fail_conditions + @success_conditions)
        @pertinent_event_types = all_conditions.collect { |i| i[:message] }.uniq
        @pertinent_event_types.each do |message_type|
            start_listening_for(message_type)
        end
    end

    # Continue listening for success / fail, but blame the quest-taker for the results
    def add_assignee(assignee)
        raise StateError, "Quest already #{state}!" if [:failed, :succeeded].includes?(@state)
        Log.debug("Assigned!")
        @state = :assigned
        @assignee = assignee
        Message.dispatch(core, :quest_received, :quest => self, :receiver => @assignee)
    end

    def fail_quest(cause)
        Log.debug("Failed!")
        @state = :failed
        if @assignee
            Message.dispatch(core, :quest_failed, :quest => self, :assignee => @assignee, :cause => cause, :penalty => @penalty)
        end
        stop_listening
    end

    def succeed_quest
        Log.debug("Success!")
        @state = :succeeded
        if @assignee
            Message.dispatch(core, :quest_success, :quest => self, :assignee => @assignee, :reward => @reward)
        end
        stop_listening
    end

    # Dish our rewards, add notoriety, etc
    def finish_quest
        @state = :finished
        raise(NotImplementedException)
    end
end
