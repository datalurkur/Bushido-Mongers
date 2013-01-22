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

    def add_attribute(attribute)
        @attributes ||= {}
        raise "Not an attribute: #{attribute}" unless @core.db.is_type?(attribute, :attribute)
        @attributes[attribute] = @core.db.create(@core, attribute)
    end

    def add_skill(skill)
        @skills ||= {}
        skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
        raise "Not a skill: #{skill}" unless @core.db.is_type?(skill_raw_name, :skill)

        # TODO - mod bonuses based on attributes
        @skills[skill] = @core.db.create(@core, skill_raw_name)
    end

    def has_attribute?(attribute)
        @attributes.has_key?(attribute)
    end

    def attribute(attribute)
        raise "Not an attribute: #{attribute}" unless @core.db.is_type?(attribute, :attribute)
        Log.warning("Doesn't have attribute: #{attribute}") unless @attributes[attribute]
        @attributes[attribute]
    end

    def has_skill?(skill)
        @skills.has_key?(skill.to_s.gsub(/_skill$/, '').to_sym)
    end

    def skill(skill)
        skill_raw_name = (skill.to_s.match(/_skill$/) ? skill : "#{skill}_skill".to_sym)
        raise "Not a skill: #{skill}" unless @core.db.is_type?(skill_raw_name, :skill)
        Log.warning("Doesn't have skill: #{skill}") unless @skills[skill]
        @skills[skill]
    end
end