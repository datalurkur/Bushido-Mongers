require './util/log'
require './util/exceptions'
require './game/tables'

=begin
    Aspect outcomes are determined using a combination of intrinsic, familiarity, and other abilities.

    If another ability contributes to the outcome of an ability, it does so additively, but scaled.  This means that if strength has an effect on climbing, someone who is weak will never (regardless of intrinsic level) be as good at climbing as someone who is strong.  Whether or not an ability is affected by another ability (and to what degree) is determined by the :associated_attribute property and the :attribute_scaling property.

    Intrinsic is used to set a baseline for ability outcomes, with familiarity providing randomness.  The more familiar someone is with an ability, the more their random outcomes will tend towards exceeding their intrinsic level (and vice-versa for low familiarity).  The upper end of familiarity outcomes does not change, but rather the lower end shrinks as familiarity increases.

    Familiarity is lost over time after a certain number of ticks have passed during which the ability was not used.  One this period has elapsed, a percentage of familiarity is lost every tick.  If an aspect does not use familiarity (such as strength) it is assumed to be 0 (maximum variance).

    TODO - Discuss intrinsic gain
=end

module Aspect
    class << self
        def at_creation(instance, params)
            initial_intrinsic = instance.class_info(:default_intrinsic) + (params[:intrinsic_bonus] || 0)
            instance.set_property(:intrinsic, initial_intrinsic)

            if instance.has_property?(:associated_attribute)
                raise(MissingProperty, "Associated attribute has no scaling value.") unless instance.has_property?(:attribute_scaling)
            end
        end

        def pack(instance)
            {:unused_for => instance.current_tick - instance.last_used}
        end

        def unpack(instance, data)
            raise(MissingProperty, "Aspect data corrupted") unless data[:unused_for]
            @current_tick = data[:unused_for]
            @last_used    = 0
        end
    end

    def attempt(difficulty, attributes)
        roll = check(difficulty, attributes)
        Log.debug(["Rolled #{roll} from attribute", self.monicker])
        roll > Difficulty.value_of(difficulty)
    end

    # TODO - Fix this ugly hack
    # This is required so that Skill can safely overload this method
    def check(difficulty, attributes)
        _check(difficulty, attributes)
    end

    def current_tick;        @current_tick ||= 0;   end
    def current_tick=(val);  @current_tick = val;   end

    def increment_tick;      self.current_tick = self.current_tick + 1; end

    def last_used;           @last_used    ||= 0;   end
    def last_used=(val);     @last_used = val;      end

    def make_check(intrinsic, variance, familiarity)
        clamp(
            intrinsic + (                            # Use intrinsic as a basic offset (ballpark the result)
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

    # Increase intrinsic
    def improve(difficulty)
        difficulty = Difficulty.value_of(difficulty) if Symbol === difficulty

        amount = 0.0025 * (1 - get_property(:intrinsic))**2 * difficulty
        set_property(:intrinsic, clamp(get_property(:intrinsic) + amount))
        Log.debug("#{self.monicker} improved to #{get_property(:intrinsic)}", 8)
    end

    private
    def _check(difficulty, attributes)
        @last_used  = @current_tick
        base_intrinsic  = get_property(:intrinsic)

        # A intrinsic may or may not be affected by another intrinsic or attribute
        associated_attribute = class_info(:associated_attribute)
        intrinsic = if associated_attribute
            attribute_scaling = class_info(:attribute_scaling)
            attribute_value   = attributes[associated_attribute].check(difficulty, attributes)
            (attribute_value * attribute_scaling) + (base_intrinsic * (1.0 - attribute_scaling))
        else
            base_intrinsic
        end

        # Use intrinsic as a baseline, and allow familiarity to vary the outcome based on the variance
        roll = make_check(intrinsic, class_info(:variance), get_property(:familiarity) || 0.0)
        Log.debug("Rolled a #{roll} for a #{difficulty} #{monicker} check", 6)
        roll
    end

    def clamp(thing)
        thing = [[thing, 1.0].min, 0.0].max
    end
end

module Skill
    class << self
        def at_creation(instance, params)
            # Check to make sure this thing is also an aspect
            raise(MissingObjectExtensionError, "Skills must use the Aspect module.") unless Aspect === instance

            initial_familiarity = instance.class_info(:default_familiarity) + (params[:familiarity_bonus] || 0)
            instance.set_property(:familiarity, initial_familiarity)
        end
    end

    def increment_tick
        super()
        languish if current_tick - last_used > class_info(:familiarity_loss)
    end

    def check(difficulty, attributes)
        practice(difficulty)
        _check(difficulty, attributes)
    end

    # Increase familiarity
    def practice(difficulty)
        # Use the difficulty of the training / task being performed to determine familiarity gain
        difficulty_adjustment = 2 ** Difficulty.difference(Difficulty.value_at(get_property(:intrinsic).floor), difficulty)
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
end
