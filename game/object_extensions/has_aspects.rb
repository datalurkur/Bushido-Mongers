require './util/exceptions'

module HasAspects
    class << self
        def at_creation(instance, params)
            # These are the two kinds of aspects right now. Later there might be more.
            instance.attributes.each do |attribute|
                instance.add_attribute(attribute)
            end
            instance.skills.each do |skill|
                instance.add_skill(skill)
            end
        end
    end

    def add_attribute(attribute, params={})
        @attributes ||= {}
        raise(UnknownType, "#{attribute} is not an attribute.") unless @core.db.is_type?(attribute, :attribute)
        @attributes[attribute] = @core.db.create(@core, attribute, params)
    end

    def add_skill(skill, params={})
        @skills ||= {}
        skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
        raise(UnknownType, "#{skill} is not a skill.") unless @core.db.is_type?(skill_raw_name, :skill)

        # TODO - mod bonuses based on attributes
        @skills[skill] = @core.db.create(@core, skill_raw_name, params)
    end

    def has_attribute?(attribute)
        @attributes.has_key?(attribute)
    end

    def attribute(attribute)
        raise(UnknownType, "#{attribute} is not an attribute.") unless @core.db.is_type?(attribute, :attribute)
        Log.warning("Doesn't have attribute: #{attribute}") unless @attributes[attribute]
        @attributes[attribute]
    end

    def has_skill?(skill)
        @skills.has_key?(skill.to_s.gsub(/_skill$/, '').to_sym)
    end

    def skill(skill)
        skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
        raise(UnknownType, "#{skill} is not a skill.") unless @core.db.is_type?(skill_raw_name, :skill)
        Log.warning("Doesn't have skill: #{skill}") unless @skills[skill]
        @skills[skill]
    end
end

module HasRandomAspects
    include HasAspects

    class << self
        def at_creation(instance, params)
            attr_names = instance.attributes
            num_attr = attr_names.size

            # Find a list of attribute values that fit within acceptable parameters.
            total_variance = num_attr * instance.class_info(:random_variance)
            acceptable_total_range = (-total_variance)..(total_variance)
            begin
                variances = Array.new(num_attr) { |i| rand }
                total = variances.inject(&:+)
            end while !acceptable_total_range.include?(total)

            attr_names.each_with_index do |name, i|
                Log.debug(instance.db.info_for(name))
                instance.add_attribute(name)
            end

            instance.skills.each do |skill|
                instance.add_skill(skill)
            end
        end
    end

    def clear_attributes
        @attributes.each do |attribute|
            attribute.destroy
        end
    end
end
