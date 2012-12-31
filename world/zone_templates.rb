require 'world/zone'
require 'util/basic'
require 'util/formatting'

class ZoneTemplate
    class << self
        def types; @types ||= {}; end

        def get_params(type)
            return {} unless type
            raise "ZoneTemplate #{type.inspect} not found" unless @types.has_key?(type)
            @types[type]
        end

        def filter_types(&block)
            if block_given?
                @types.select { |type, params| block.call(type, params) }.map(&:first)
            else
                @types.keys
            end 
        end

        def required_params; [
            :keywords,
            :depth_range
        ]; end

        def define(type, properties, &block)
            required_params.each { |key| raise "ZoneTemplate #{type} lacks key #{key}" unless properties.has_key?(key) }
            types[type] = properties
            types[type].merge!(:generate_proc => block) if block_given?
        end

        def random(parent, size, depth)
            possible = ZoneTemplate.types.keys
            never = []
            if parent
                possible = get_params(parent)[:may_contain] || possible
                never = get_params(parent)[:never_contains] || never
            end

            eligible_types = filter_types do |type, params|
                possible.include?(type) &&
                !never.include?(type) &&
                ((params[:depth_range] & depth).size > 0)
            end

            Log.debug("eligible_types is #{eligible_types.inspect}", 6)

            type = nil
            if eligible_types.empty?
                # Just use the parent, if it exists, or a random template.
                type = (parent && Chance.take(:coin_toss)) ? parent : filter_types.rand
            else
                type = eligible_types.rand
            end

            params = get_params(type).dup
            params[:template] = type
            params[:depth] = depth
            params.delete(:depth_range)
            return merge_template_parameters(params, get_params(parent))
        end

        # Merge ZoneTemplate parameter sets, respecting the nature of each special parameter
        # The default case is for a child field to override a parent field
        # FIXME: Note that this doesn't work all the way up the chain yet. Only parent
        # zone parameters are currently inherited.
        def merge_template_parameters(child, parent)
            result = {}

            # First merge in the parent params, then the child params, allowing the child params to override
            result.merge!(parent)
            result.merge!(child)

            # We want to merge both sets of keywords together
            # FIXME - Deal with keyword incompatibilities cleverly somehow here
            result[:keywords] = (child[:keywords] + (parent[:keywords] || [])).uniq

            # Return the resultant hash
            result
        end

        # Takes a ZoneLeaf or ZoneContainer, and populates it. Currently does nothing.
        def populate_zone(zone, size, depth)
            raise "#{zone.inspect} is not a ZoneWithKeywords!" unless zone.respond_to?(:zone)

            # FIXME: This should use merged params somehow.
            params = get_params(zone.zone)

            # Populate it with stuff
            if params[:generate_proc]
                params[:generate_proc].call(zone, params)
            else
                default_generation(zone, params)
            end
        end

        def default_generation(zone, params)
            # FIXME
        end
    end
end

ZoneTemplate.define(:sanctuary,
    :depth_range     => 1..3,
    :may_contain     => [:tavern, :inn],
    :never_contains  => [:dungeon],
    :always_spawns   => [:peacekeeper],
    :may_spawn       => [:merchant],
    :never_spawns    => [:monster],
    :keywords        => [:haven]
)

ZoneTemplate.define(:meadow,
    :depth_range   => 0..3,
    :keywords      => [:grassy],
    :always_spawns => [:monster]
)

ZoneTemplate.define(:castle,
    :depth_range     => 0..4,
    :always_contains => [:barracks, :portcullis],
    :may_contain     => [:sewer, :tower, :dungeon],
    :never_contains  => [:mountain],
    :keywords        => [:constructed],
    :optional_keywords => [:dank, :inhabited],
    :always_spawns   => [:monster]
)

ZoneTemplate.define(:sewer,
    :depth_range    => 0..2,
    :keywords       => [:dank, :wet],
    :always_spawns  => [:monster]
)

ZoneTemplate.define(:dock,
    :depth_range     => 1..1,
    :always_contains => [:pier],
    :may_contain     => [:boat],
    :keywords        => [],
    :always_spawns   => [:monster]
)

ZoneTemplate.define(:boat,
    :depth_range    => 0..2,
    :req_parents    => [:dock],
    :keywords       => [:wet],
    :always_spawns  => [:monster]
)

# Soon...
=begin
ZoneTemplate.define(:temple_that_serves_as_the_final_bastion_of_light_in_an_otherwise_evil_forest, {:keywords=>[], :depth_range=>1..3})
ZoneTemplate.define(:temple)
ZoneTemplate.define(:barracks)
ZoneTemplate.define(:portcullis)
ZoneTemplate.define(:tower)
ZoneTemplate.define(:dungeon)
ZoneTemplate.define(:mountain)
=end