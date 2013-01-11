require './util/log'

# FIXME - Make this into a usable module like the rest
module Ability
    def attempt(difficulty)
        Log.debug("Attempting to perform #{difficulty} task")
        last_used = current_tick

        result = make_check
        # FIXME - Perform a lookup to determine whether or not the result surpasses the difficulty
    end

    def tick
        current_tick += 1
        languish if current_tick - last_used > @properties[:familiarity_loss]
    end

    private
    def current_tick; @current_tick ||= 0; end
    def last_used;    @last_used    ||= 0; end

    # Make a check using skill and familiarity to determine the outcome
    def make_check
        skill_check       = rand(@properties[:skill])
        familiarity_check = rand(@properties[:familiarity]) - @properties[:familiarity]
        # TODO - Probably add scaling to the familiarity check
        result = skill_check + familiarity_check
    end

    # Increase familiarity
    def practice(difficulty)
        # Use the difficulty of the training / task being performed to determine familiarity gain
        # FIXME
        @properties[:familiarity] += amount
    end

    # Decrease familiarity
    def languish
        # Exponentially decrease familiarity
        #  (familiarity loss slows as time spent away from a task increases)
        # FIXME
        @properties[:familiarity] -= amount
        clamp(@properties[:familiarity])
    end

    # Increase skill
    def improve(difficulty)
        # Use the difficulty of the training / task being performed to determine skill gain
        # FIXME
        @properties[:skill] += amount
        clamp(@properties[:skill])
    end

    def clamp(thing)
        thing = [[thing, 1.0].min, 0.0].max
    end
end
