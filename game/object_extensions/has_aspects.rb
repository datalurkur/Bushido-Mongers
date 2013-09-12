require './util/exceptions'

module HasAspects
    class << self
        def listens_for(i); [:tick]; end

        def pack(instance)
            {
                :attributes => instance.attributes,
                :skills     => instance.skills
            }
        end

        def unpack(core, instance, raw_data)
            raise(MissingProperty, "HasAspects data corrupted") unless raw_data[:skills] && raw_data[:attributes]
            instance.set_predefined(raw_data[:attributes], raw_data[:skills])
        end

        def at_creation(instance, params)
            instance.setup_attribute_set
        end

        def at_message(instance, message)
            if message.type == :tick
                instance.tick_aspects
            end
        end
    end

    # =============================
    # ATTRIBUTE SETUP AND ACCESSORS
    # =============================
    def set_predefined(attributes, skills)
        @attributes = attributes
        @skills     = skills
    end
    def attributes; @attributes ||= {}; end
    def setup_attribute_set
        # Compute a set of variances
        variances = if class_info[:random_attributes]
            default_values     = properties[:attributes].collect { |a| @core.db.info_for(a)[:default_intrinsic] }
            relative_offset    = class_info[:attribute_offset] || 0
            variance_per_value = class_info[:random_variance]

            generate_variances(default_values, variance_per_value, relative_offset)
        else
            Array.new(properties[:attributes].size, 0)
        end

        # Add the actual attributes
        Log.debug("Adding #{properties[:attributes].size} attributes for #{monicker}", 8)
        properties[:attributes].each_with_index do |name, i|
            attr = @core.create(name, {:intrinsic_bonus => variances[i]})
            Log.debug("Setting attribute #{name} to #{attr.uid} (#{attr.inspect})", 8)
            attributes[name] = attr.uid
        end
    end

    # =========================
    # SKILL SETUP AND ACCESSORS
    # =========================
    def skills; @skills ||= {}; end
    # This is performed after creation, by whatever code has knowledge of the agent's profession
    def setup_skill_set(added_skills=[])
        properties[:skills].concat(added_skills)
        properties[:skills].uniq!

        # Compute a set of variances
        variances = if class_info[:random_skills]
            default_values     = properties[:skills].collect { |s| @core.db.info_for(s)[:default_intrinsic] }
            relative_offset    = class_info[:skill_offset] || 0
            # FIXME: this should probably be different for attributes and skills.
            variance_per_value = class_info[:random_variance]

            generate_variances(default_values, variance_per_value, relative_offset)
        else
            Array.new(properties[:skills].size, 0)
        end

        # Add the actual skills
        properties[:skills].each_with_index do |name, i|
            # TODO - mod bonuses based on attributes
            skill = @core.create(name, :intrinsic_bonus => variances[i])
            skills[name] = skill.uid
        end
    end

    # =================
    # COMMON PUBLIC API
    # =================
    def get_aspect(aspect)
        if attributes.has_key?(aspect)
            @core.lookup(attributes[aspect])
        elsif skills.has_key?(aspect)
            @core.lookup(skills[aspect])
        elsif @core.db.is_type?(aspect, :skill)
            skill = @core.create(aspect)
            skills[aspect] = skill.uid
            skill
        else
            raise(UnknownType, "#{aspect} is not a defined skill or aspect")
            nil
        end
    end

    def make_attempt(aspect_name, difficulty)
        (difficulty = Difficulty.value_of(difficulty)) if (Symbol === difficulty)
        Log.debug("#{monicker} making an attempt to use #{aspect_name} with difficulty #{difficulty}")

        aspect = get_aspect(aspect_name)
        raise(MissingProperty, "#{self.monicker} has no aspect #{aspect_name}") if aspect.nil?

        result = aspect.make_check(attributes)
        margin = result - difficulty
        Log.debug("Resulting check and margin of success: #{result} / #{margin}")

        aspect.improve(margin)
        aspect.practice(margin) if aspect.uses?(Skill)

        return margin
    end

    def make_opposed_attempt(aspect_name, target)
        Log.debug("#{monicker} uses #{aspect_name} against #{target.monicker}")

        aspect = get_aspect(aspect_name)
        raise(MissingProperty, "#{self.monicker} has no aspect #{aspect_name}") if aspect.nil?
        attempt_result = aspect.make_check(attributes)

        if target.uses?(HasAspects) && target.uses?(Perception)
            opposed_results = []
            aspect.class_info[:opposed_aspects].each do |opposed|
                opposition = target.make_attempt(opposed, attempt_result)
                opposed_results << [opposed, opposition]

                aspect.improve(-opposition)
                aspect.practice(-opposition) if aspect.uses?(Skill)

                if opposition > 0
                    return [true, opposed_results]
                end
            end
            return [false, opposed_results]
        else
            margin = attempt_result - Difficulty.value_of(:trivial)
            aspect.improve(margin)
            aspect.practice(margin) if aspect.uses?(Skill)
            return [margin > 0, [:difficulty, margin]]
        end
    end

    def tick_aspects
        attributes.each { |k,a_id| @core.lookup(a_id).increment_tick }
        skills.each     { |k,s_id| @core.lookup(s_id).increment_tick }
    end

    # ================
    # INTERNAL METHODS
    # ================
    private
    # Find a list of modifiers to the default attributes whose total fits within the range.
    def generate_variances(default_values, variance_per_value, relative_offset)
        return [] if default_values.empty?

        num_values = default_values.size
        if variance_per_value == 0.0 && relative_offset == 0.0
            # Nothing to be done; return 0 variances.
            Array.new(num_values, 0)
        end

        defaults_total = default_values.inject(&:+)

        total_variance = num_values * variance_per_value.abs
        # At least one endpoint of the variance must be within the range that
        #  can be generated (0..num_values), so clamp at extremes.
        range_begin = [(defaults_total + relative_offset - total_variance), 0].max
        range_end   = [(defaults_total + relative_offset + total_variance), num_values].min
        # Swap the end-points if they're inverted.
        range_begin = [range_begin, range_end].min
        range_end   = [range_begin, range_end].max
        # The defaults total + the variances total must be with this range.
        acceptable_range = range_begin..range_end
        range_size       = range_end - range_begin
        # If the range_size is zero the acceptable_range requested is impossible to generate.
        if range_size == 0
            raise "Can't generate #{num_values} random values for #{self.monicker} based on " +
                  "random_variance #{variance_per_value.abs} and relative_offset #{relative_offset}!"
        end
        # Warn if acceptable_range is unlikely to be hit.
        # The basic range check doesn't work well because it matters WHERE in the range we're looking.
        #   The variance generation further below consists of multiple discrete events, which brings
        #   the central limit theorem into play, and makes it exceedingly unlikely that total values near
        #   the boundaries of the variance generation range (large stddev) will be hit. Practically,
        #   this only happens with tiny random_variance and large offsets that push the acceptable_range
        #   close to 0 or num_values, so check that the range is not very close to those boundaries.
        # FIXME: These values are all experimentally hard-coded. Really we should calculate the distribution
        #   function of the acceptable_range being hit and bark if it's low (P<0.05? P<0.01? We'll eventually be
        #   generating a LOT of these).
        report_generation_count = false
        if (num_values / range_size > 1_000) || (range_end < num_values / 50.0) || (range_begin > num_values - (num_values / 50.0))
            Log.warning("Unlikely acceptable value range (#{acceptable_range}) for #{self.monicker} " +
                        "may take a while to generate.")
            report_generation_count = true
        end

        # Actually generate and check variances until we find an acceptable list.
        # Generated range will always be within (0, num_values).
        variances = []
        count = 0
        begin
            count += 1
            variances = Array.new(num_values) do |i|
                raise "Default attribute value outside [0,1]!" unless (0..1).include?(default_values[i])
                # generate permutation between (-default, 1 - default) to cover all default attribute possibilities
                rand_variance = rand - default_values[i]
                rand_variance
            end
            variance_total = variances.inject(&:+)
        end while !acceptable_range.include?(defaults_total + variance_total)
        Log.debug("Generated after #{count} iterations.") if report_generation_count
        variances
    end
end
