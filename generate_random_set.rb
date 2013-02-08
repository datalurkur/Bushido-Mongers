def generate_random_set(default_attributes, relative_offset)
    modifiers = []
    default_attributes.each_with_index do |default,i|
        # Allow the modifier for this attribute to vary over the entire allowable range [0,1]
        modifiers << [rand - default, i]
    end

    # Determine the required offset per-value to converge on the given "relative_offset"
    sum    = modifiers.inject(0) { |sum, e| sum + e.first }
    offset = (relative_offset - sum)

    # Attempt to converge the set
    mods_left        = modifiers.size
    sorted_modifiers = modifiers.sort do |x,y|
        (x.first + default_attributes[x.last]) <=> (y.first + default_attributes[y.last])
    end

    if offset > 0
        # The attribute set isn't awesome enough
        sorted_modifiers.reverse!
        sorted_modifiers.collect! do |m,i|
            avg_offset = offset / mods_left
            mods_left -= 1
            leftover = (default_attributes[i] + m + avg_offset) - 1
            result = if leftover > 0
                difference = (avg_offset - leftover)
                offset -= difference
                m + difference
            else
                offset -= avg_offset
                m + avg_offset
            end
            [result, i]
        end
    elsif offset < 0
        # The attribute set isn't shitty enough
        sorted_modifiers.collect! do |m,i|
            avg_offset = offset / mods_left
            mods_left -= 1
            leftover = (default_attributes[i] + m + avg_offset)
            result = if leftover < 0
                difference = avg_offset - leftover
                offset -= difference
                m + difference
            else
                offset -= avg_offset
                m + avg_offset
            end
            [result, i]
        end
    end

    if offset != 0
        # Degenerate case, assume we've done all we can and return
        puts "Warning! Degenerate case!"
    end

    # Re-sort according to the original indices
    sorted_modifiers.sort_by { |m,i| i }.collect { |m,i| m }
end

def get_modifiers_and_add(attrs, mods)
    (0...attrs.size).collect do |i|
        attrs[i] + mods[i]
    end
end

attribute_defaults = [0.5, 0.5, 0.1, 0.9]
modifiers = generate_random_set(attribute_defaults, 1.0)
puts modifiers.inspect
results = get_modifiers_and_add(attribute_defaults, modifiers)
puts results.inspect
