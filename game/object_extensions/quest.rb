module Quest
    class << self
        # For pack and unpack, we need a way to reference BushidoObjects uniquely without a pointer (basically, a unique ID) so that they can be unliked but still reconstructable
        def pack(instance)
            raise(NotImplementedException)
        end

        def unpack(core, instance, raw_data)
            raise(NotImplementedException)
        end

        def listens_for(instance)
            instance.pertinent_event_types
        end

        def at_creation(instance, params)
            # TODO - Set up failure / success triggers using the params
            raise(NotImplementedException)

            # Example:
            # params => {
            #   :failure_conditions => [{:type => :object_destroyed, :object => <Item>}],
            #   :success_conditions => [{:type => :object_moved, :object => <Item>, :criteria => <Destination>}],
            #   :rewards => [{:type => :object, :count => 100, :object => <Coin>}],
            #   :notoriety => {:type => :good_deed, :magnitude => :minor}
            # This quest will listen for object destruction and object movement

            # When we're all done, start listening for victory / failure conditions
            instance.create_quest(params)
        end

        def at_message(instance, message)
            return unless instance.pertinent_event_types.include?(message.type)
            instance.fail_conditions.each do |condition|
                if condition_met?(condition, message)
                    instance.fail_quest(condition)
                    return
                end
            end
            instance.success_conditions.each do |condition|
                if condition_met?(condition, message)
                    instance.succeed_quest(condition)
                    return
                end
            end
        end

        def condition_met?(condition, message)
            raise(NotImplementedException)
        end
    end

    attr_reader :fail_conditions, :success_conditions, :pertinent_event_types

    # Start listening for success / fail
    def create_quest(params)
        @fail_conditions    = params[:failure_conditions]
        @success_conditions = params[:success_conditions]

        all_conditions = (@fail_conditions + @success_conditions)
        @pertinent_event_types = all_conditions.collect { |i| i[:type] }.uniq
        @pertinent_event_types.each do |event_type|
            start_listening_for(event_type)
        end

        @rewards            = params[:rewards]
        @notoriety          = params[:notoriety]

        @state              = :created
    end

    # Continue listening for success / fail, but blame the quest-taker for the results
    def assign_quest
        @state = :assigned
        raise(NotImplementedException)
    end

    # Stop listening
    def fail_quest(failed_condition)
        @state = :failed
        raise(NotImplementedException)
    end

    # Stop listening
    def succeed_quest(succeeded_condition)
        @state = :succeeded
        raise(NotImplementedException)
    end

    # Dish our rewards, add notoriety, etc
    def finish_quest
        @state = :finished
        raise(NotImplementedException)
    end
end
