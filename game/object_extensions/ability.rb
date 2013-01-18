require './util/log'

module Ability
    class << self
        def at_creation(instance, params)
            initial_skill       = instance.class_info(:default_skill)       + (params[:skill_bonus]       || 0)
            initial_familiarity = instance.class_info(:default_familiarity) + (params[:familiarity_bonus] || 0)

            instance.set_property(:skill,       initial_skill)
            instance.set_property(:familiarity, initial_familiarity)

            instance.start_listening_for(:core)
        end

        def at_message(instance, message)
            case message.type
            when :tick
                instance.tick
            end
        end
    end

    def attempt(difficulty)
        Log.debug("Attempting to perform #{difficulty} task")
        last_used = current_tick

        result = make_check
        return result > Difficulty.value_of(difficulty)
    end

    def tick
        current_tick += 1
        languish if current_tick - last_used > get_property(:familiarity_loss)
    end

    private
    def current_tick; @current_tick ||= 0; end
    def last_used;    @last_used    ||= 0; end

    # Make a check using skill and familiarity to determine the outcome
    def make_check
        skill_check       = rand(get_property(:skill))
        familiarity_check = rand(get_property(:familiarity)) - get_property(:familiarity)
        # TODO - Probably add scaling to the familiarity check
        result = skill_check + familiarity_check
    end

    # Increase familiarity
    def practice(difficulty)
        # Use the difficulty of the training / task being performed to determine familiarity gain
        # FIXME
        set_property(:familiarity, get_property(:familiarity) + amount)
    end

    # Decrease familiarity
    def languish
        # Exponentially decrease familiarity
        #  (familiarity loss slows as time spent away from a task increases)
        # FIXME
        set_property(:familiarity, clamp(get_property(:familiarity) - amount))
    end

    # Increase skill
    def improve(difficulty)
        # Use the difficulty of the training / task being performed to determine skill gain
        # FIXME
        set_property(:skill, clamp(get_property(:skill) + amount))
    end

    def clamp(thing)
        thing = [[thing, 1.0].min, 0.0].max
    end
end
