require 'world/zone'
require 'util/basic'
require 'util/formatting'

class ZoneTemplate
    class << self
        def types; @types ||= {}; end

        def get_params(type)
            raise "ZoneTemplate #{type} not found" unless @types.has_key?(type)
            @types[type]
        end

        def filter_types(&block)
            if block_given?
                @types.keys.select { |type| block.call(get_params(type)) }
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

        def generate_random(depth_range, size)
            eligible_types = filter_types { |params| (params[:depth_range] & depth_range).size > 0 }

            type  = generate(eligible_types.rand_key, size)
            depth = (get_params(type)[:depth_range] & depth_range).rand

            generate(type, size, depth)
        end

        # Generate a specific type of size x size dimensions and depth
        # We want to give ZoneTemplates the ability to have an effect on the generation of sub-zones
        # parent_params is in place for when this method is called from within another ZoneTemplate
        def generate(type, size, depth, parent_params={})
            params = get_params(type)

            # We need special functionality to do this, see the method definition for more information
            # Another possibility is just passing both sets and letting the generation code deal with them
            merged_params = merge_template_parameters(params, parent_params)

            # FIXME - Generate a random name using the keywords
            name = "Generic Zone Name"

            # Setup the empty zone
            zone = setup_zone(name, size, depth)

            # Populate it with stuff
            if params[:generate_proc]
                params[:generate_proc].call(zone, merged_params)
            else
                default_generation(zone, merged_params)
            end

            # Toss it back
            zone
        end

        # Merge ZoneTemplate parameter sets, respecting the nature of each special parameter
        # The default case is for a child field to override a parent field
        def merge_template_parameters(child, parent)
            result = {}

            # First merge in the parent params, then the child params, allowing the child params to override
            result.merge!(parent)
            result.merge!(child)

            # We want to merge both sets of keywords together
            # FIXME - Deal with keyword incompatibilities cleverly somehow here
            result[:keywords] = (child[:keywords] + parent[:keywords]).uniq

            # Return the resultant hash
            result
        end

        def setup_zone(name, size, depth)
            zone = if depth == 1
                ZoneLeaf.new(name)
            else
                ZoneContainer.new(name, size, depth)
            end
            zone
        end

        def default_generation(zone, params)
            # FIXME
        end
    end
end

ZoneTemplate.define(:sanctuary,
    :depth_range     => 2..3,
    :always_contains => [:haven],
    :may_contain     => [:tavern, :inn],
    :never_contains  => [:dungeon],
#    :always_spawns   => [:peacekeeper],
#    :may_spawn       => [NPC::Merchant],
#    :never_spawns    => [NPC::Monster]
    :keywords        => [:peaceful]
)

ZoneTemplate.define(:haven,
    :depth_range     => 1..2,
    :always_contains => [:haven],
    :may_contain     => [:tavern, :inn],
    :never_contains  => [:dungeon],
#    :always_spawns   => [:peacekeeper],
#    :may_spawn       => [NPC::Merchant],
#    :never_spawns    => [NPC::Monster]
    :keywords        => [:peaceful]
)

ZoneTemplate.define(:meadow,
                    :depth_range=>1..3,
                    :keywords=>[:grassy]
                    )

ZoneTemplate.define(:castle,
                    :depth_range     => 1..4,
                    :always_contains => [:barracks, :portcullis],
                    :may_contain     => [:sewer, :tower, :dungeon],
                    :never_contains  => [:mountain],
                    :keywords        => [:constructed],
                    :optional_keywords => [:dank, :inhabited]
                    )

ZoneTemplate.define(:sewer,
                    :keywords=>[:dank, :wet],
                    :depth_range=>1..2,
                    :child_of=>[:castle]
                    )

ZoneTemplate.define(:dock,
                    :depth_range => 2..3,
                    :keywords => []
                    )

ZoneTemplate.define(:boat,
                    :depth_range => 1..2,
                    :req_parents=>[:dock],
                    :keywords => [:wet]
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