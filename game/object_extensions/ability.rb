require './util/log'

=begin
    Ability outcomes are determined using a combination of skill, familiarity, and other abilities.

    If another ability contributes to the outcome of an ability, it does so additively, but scaled.  This means that if strength has an effect on climbing, someone who is weak will never (regardless of skill level) be as good at climbing as someone who is strong.  Whether or not an ability is affected by another ability (and to what degree) is determined by the :associated_attribute property and the :attribute_scaling property.

    Skill is used to set a baseline for ability outcomes, with familiarity providing randomness.  The more familiar someone is with an ability, the more their random outcomes will tend towards exceeding their skill level (and vice-versa for low familiarity).  The upper end of familiarity outcomes does not change, but rather the lower end shrinks as familiarity increases.

    Familiarity is lost over time after a certain number of ticks have passed during which the ability was not used.  One this period has elapsed, a percentage of familiarity is lost every tick.

    TODO - Discuss skill gain
=end

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

    def attempt(difficulty, attributes)
        Log.debug("Attempting to perform #{difficulty} task")
        @last_used  = @current_tick
        base_skill  = get_property(:skill)

        # A skill may or may not be affected by another skill or attribute
        associated_attribute = class_info(:associated_attribute)
        skill = if associated_attribute
            attribute_scaling = class_info(:attribute_scaling)
            (attributes[associated_attribute] * attribute_scaling) + (base_skill * (1.0 - attribute_scaling))
        else
            base_skill
        end

        # Use skill as a baseline, and allow familiarity to vary the outcome based on the variance
        roll   = make_check(skill, get_property(:variance), get_property(:familiarity))
        result = (roll > Difficulty.value_of(difficulty))

        practice(difficulty, result)

        return result
    end

    private
    def current_tick; @current_tick ||= 0; end
    def last_used;    @last_used    ||= 0; end

    def tick
        current_tick += 1
        languish if current_tick - last_used > get_property(:familiarity_loss)
    end

    def make_check(skill, variance, familiarity)
        clamp(
            skill + (                                # Use skill as a basic offset (ballpark the result)
                variance * (                         # Scale the result of our randomness by the variance
                    (
                        rand() * (1.0 - familiarity) # Generate a random number on the range [0, 1-f]
                                                     # (Higher f = smaller range)
                    ) + (
                        familiarity - 0.5            # Shift the random number upwards by half of max f
                                                     # (Approaching max f eliminates lower end
                                                     #  without sacrificing upper end)
                    )
                )
            )
        )
    end

    # Increase familiarity
    def practice(difficulty, result)
        # Use the difficulty of the training / task being performed to determine familiarity gain
        difficulty_adjustment = 2 ** Difficulty.difference(Difficulty.value_of(get_property(:skill).floor), difficulty)
        amount = get_property(:familiarity_gain_rate) * difficulty_adjustment
        set_property(:familiarity, get_property(:familiarity) + amount)
    end

    # Decrease familiarity
    def languish
        # Exponentially decrease familiarity
        #  (familiarity loss slows as time spent away from a task increases)
        new_level = clamp(get_property(:familiarity) * (1.0 - get_property(:familiarity_loss_rate)))
        set_property(:familiarity, new_level)
    end

    # Increase skill
    def improve(difficulty, result)
        # Use the difficulty of the training / task being performed to determine skill gain
        # FIXME
        raise "NOT IMPLEMENTED"
        set_property(:skill, clamp(get_property(:skill) + amount))
    end

    def clamp(thing)
        thing = [[thing, 1.0].min, 0.0].max
    end
end
