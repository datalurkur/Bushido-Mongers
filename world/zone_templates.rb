require 'world/zone'
require 'util/basic'

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

ZoneTemplate.define(:meadow, {})

=begin
require 'basic_extensions'

# FIXME: Restructure ZoneTemplate as a factory.
# FIXME: Add keyword storing.

class ZoneTemplate
    class << self
        def register_template(template_class)
            @templates ||= []
            @templates << template_class
        end

        def define(zone, args = {})
            args[:depth_range] = 1..2 unless args[:depth_range]
            args[:depth_range] = (args[:depth_range]..args[:depth_range]) if Numeric === args[:depth_range]

            class_eval %{
                class #{zone.to_s.sentence}
                    DEPTH_RANGE = #{args[:depth_range]}
                    
                    def initialize
                        puts "Creating a new \#\{self.class\}."
                    end
                end
                self.register_template(#{zone.to_s.sentence})
            }
        end

        def rand(depth = :any)
            return @templates.rand if depth == :any
            return @templates.select { |t| t::DEPTH_RANGE.include?(depth) }.rand
        end
    end
end

if $0 == __FILE__
    ZoneTemplate.define(:castle, :depth_range => 1..2,
                        :keywords => [:constructed],
                        :optional_keywords => [:dank, :inhabited])

    puts "There's a #{ZoneTemplate::Castle} class now."
    puts "Instantiating: #{ZoneTemplate::Castle.new}."

    ZoneTemplate.define("Mountain_Range", :depth_range => 3..5,
                        :keywords => [:mountainous])

    ZoneTemplate.define("OnABoat", :depth_range => 1..3,
                        :keywords => [:wet])

    puts "There's a #{ZoneTemplate::OnABoat} class now."
    puts "Instantiating: #{ZoneTemplate::OnABoat.new}."

    p ZoneTemplate.rand
    p ZoneTemplate.rand(2)
    p ZoneTemplate.rand(3)
    p ZoneTemplate.rand(5)
end
=end
