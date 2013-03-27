require './util/exceptions'

module HasAspects
    class << self
        def listens_for(i); [:tick]; end

        def pack(instance)
            raw_data = {:attributes => {}, :skills => {}}
            instance.attributes.each do |key, value|
                raw_data[:attributes][key] = SafeBushidoObject.pack(value)
            end
            instance.skills.each do |key, value|
                raw_data[:skills][key] = SafeBushidoObject.pack(value)
            end
            raw_data
        end

        def unpack(core, instance, raw_data)
            raise(MissingProperty, "HasAspects data corrupted") unless raw_data[:skills] && raw_data[:attributes]
            raw_data[:attributes].each_pair do |attribute, raw_attribute_data|
                actual = SafeBushidoObject.unpack(core, raw_attribute_data)
                instance.attributes[attribute] = actual
            end
            raw_data[:skills].each_pair do |skill, raw_skill_data|
                actual = SafeBushidoObject.unpack(core, raw_skill_data)
                instance.skills[skill] = actual
            end
        end

        def at_creation(instance, params)
            instance.setup_attribute_set
            # This is performed after creation, by whatever code has knowledge of the agent's profession
            #setup_skill_set
        end

        def at_message(instance, message)
            instance.attributes.each { |k,a| a.increment_tick }
            instance.skills.each     { |k,s| s.increment_tick }
        end
    end

    def attributes; @attributes ||= {}; end
    def setup_attribute_set
        # Compute a set of variances
        variances = if class_info[:random_attributes]
            default_values     = get_attribute_defaults(properties[:attributes])
            relative_offset    = class_info[:attribute_offset] || 0
            variance_per_value = class_info[:random_variance]

            generate_variances(default_values, variance_per_value, relative_offset)
        else
            Array.new(properties[:attributes].size, 0)
        end

        # Add the actual attributes
        properties[:attributes].each_with_index do |name, i|
            attributes[name] = @core.create(name, {:intrinsic_bonus => variances[i]})
        end
    end
    def attribute(attribute)
        raise(UnknownType, "#{attribute} is not an attribute.") unless @core.db.is_type?(attribute, :attribute)
        Log.warning("Doesn't have attribute: #{attribute}") unless attributes.has_key?(attribute)
        attributes[attribute]
    end

    def skills; @skills ||= {}; end
    def setup_skill_set(added_skills=[])
        properties[:skills].concat(added_skills)
        properties[:skills].uniq!

        # Compute a set of variances
        variances = if class_info[:random_skills]
            default_values     = get_skill_defaults(properties[:skills])
            relative_offset    = class_info[:skill_offset] || 0
            # FIXME: this should probably be different for attributes and skills.
            variance_per_value = class_info[:random_variance]

            generate_variances(default_values, variance_per_value, relative_offset)
        else
            Array.new(properties[:skills].size, 0)
        end

        # Add the actual skills
        properties[:skills].each_with_index do |name, i|
            skill_raw_name = (name.to_s.match(/_skill$/) ? name : "#{name}_skill".to_sym)
            # TODO - mod bonuses based on attributes
            skills[name] = @core.create(skill_raw_name, {:intrinsic_bonus => variances[i]})
        end
    end

    def has_skill?(skill)
        # TODO - Kill off this horrible _skill crap
        skills.has_key?(skill.to_s.gsub(/_skill$/, '').to_sym)
    end

    def skill(skill)
        # TODO - Kill off this horrible _skill crap
        skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
        raise(UnknownType, "#{skill} is not a skill.") unless @core.db.is_type?(skill_raw_name, :skill)
        Log.warning("Doesn't have skill: #{skill}") unless has_skill?(skill)
        skills[skill]
    end

    def get_aspect(aspect)
        attributes.has_key?(aspect) ? attributes[aspect] :
        has_skill?(aspect)          ? skill(aspect) : nil
    end

    # -- #

    def make_check(aspect_sym, difficulty = Difficulty.standard)
        aspect = get_aspect(aspect_sym)
        raise "No aspect #{aspect_sym} on #{self.monicker}!" if aspect.nil?

        aspect.improve(difficulty) if has_skill?(aspect_sym)
        aspect.check(difficulty, attributes)
    end

    # FIXME - right now difficulty affects aspect, associate attribute, AND opposer difficulty.
    def opposed_check(aspect, difficulty, opposer, opposed_aspect)
        roll = make_check(aspect, difficulty)
        # If opposer hasn't aspects, just do a regular difficulty check.
        opposed_roll =  opposer.uses?(HasAspects) ?
                        opposer.make_check(opposed_aspect, difficulty) :
                        Difficulty.value_of(difficulty)
        Log.debug([roll, opposed_roll], 6)
        return roll > opposed_roll
    end

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

    def get_attribute_defaults(names)
        names = Array(names)
        names.collect do |name|
            @core.db.info_for(name)[:default_intrinsic]
        end
    end

    def get_skill_defaults(names)
        names = Array(names)
        names.collect do |skill|
            skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
            @core.db.info_for(skill_raw_name)[:default_intrinsic]
        end
    end
end
