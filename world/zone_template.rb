require 'world/zone'
require 'util/basic'
require 'util/formatting'

class Zone
    class << self
        # Returns args used to populate gen_area_name, Area.new and Room.new.
        def create(core, parent, depth)
            args = if parent
                # Inherit a keyword from the parent.
                { :template => find_child(core.db, parent, depth),
                  :inherited_keywords => ([core.db.info_for(parent.type, :keywords).rand] || [])
                }
            else
                { :template => find_random(core.db, depth) }
            end

            args[:depth] = depth
            args[:zone]  = core.db.create(core, args[:template], args)

            args.delete(:inherited_keywords) # Shouldn't need this again.
            return args
        end

        private
        def zones_of_depth(db, depth, list = db.types_of(:zone))
            list.select do |zone|
                db.info_for(zone, :depth_range).include?(depth)
            end
        end

        def find_child(db, parent, depth)
            Log.debug(parent.inspect)
            potential_zones = zones_of_depth(db, depth, db.info_for(parent.type, :child_zones))

            if potential_zones.empty?
                potential_zones = zones_of_depth(db, depth)
            end

            type = potential_zones.rand
            raise "Found invalid child zone type #{type} in #{parent.type}!\n" unless db[type]
            return type
        end

        def find_random(db, depth)
            return zones_of_depth(db, depth).rand
        end
    end
end

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