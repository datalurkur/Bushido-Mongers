require './game/managers/manager'

# TODO
#   - Listen for ticks and automatically spawn new population members
#   - Listen for death messages and adjust rarity accordingly
#   - Listen for move messages and disable spawns that have players in them (no fun in spawning things directly on top of players)
#   - Make the population manager save-/load-friendly

class PopulationManager < Manager
    def listens_for; [:unit_animated,:unit_moves,:unit_moved,:unit_killed,:unit_renamed]; end

    def setup
        @named          = {}
        @groups         = {}
        @diabled_spawns = []

        load_from_raws

        super()
    end

    def teardown
        super()

        @groups          = nil
        @disabled_spawns = nil
    end


    def process_message(message)
        # Get the population type involved if this will affect a population type
        unit = case message.type
        when :unit_moves,:unit_moved
            message.agent
        when :unit_animated,:unit_killed
            message.target
        end

        return if unit && @groups[unit.get_type].nil?

        case message.type
        when :unit_moves,:unit_moved
            unit_moves(unit, message.origin, message.destination)
        when :unit_killed
            unit_moves(unit, message.location, nil)
        when :unit_animated
            unit_moves(unit, nil, message.location)
        when :tick
            Log.info("#{self.class} spawning new population members", 4)
            Log.warning("IMPLEMENT ME")
        when :unit_renamed
            if message.params[:old_name]
                old_name = hash_name(message.old_name)
                new_name = hash_name(message.name)
                if @named[old_name]
                    @named[new_name] = @named[old_name]
                    @named.delete(old_name)
                end
            end
        else
            Log.warning("#{self.class} ignoring message type #{message.type}")
        end
    end

    def [](type)
        raise(ArgumentError, "Unknown population #{type.inspect}") unless @groups.has_key?(type)
        @groups[type]
    end

    def each(&block)
        @groups.each do |type|
            yield(type)
        end
    end

    def locate(type_or_name)
        if @groups[type_or_name]
            return @groups[type_or_name][:populations]
        else
            name = hash_name(type_or_name)
            if @named[name]
                return {@named[name] => 1}
            else
                return {}
            end
        end
    end
    def enable_spawn(location)
        @disabled_spawns.delete(location)
    end
    def disable_spawn(location)
        (@disabled_spawns << location) unless @disabled_spawns.include?(location)
    end


    private
    def load_from_raws
        @core.db.instantiable_types_of(:archetype).each do |npc_type|
            npc_info = @core.db.info_for(npc_type)
            add_group(npc_type, npc_info[:spawns_in], npc_info[:spawn_rarity])
        end
    end

    def add_group(type, spawn_locations, rarity)
        Log.debug(["Adding #{rarity.inspect} population group #{type.inspect}", spawn_locations], 5)
        @groups[type] = {
            :spawns         => spawn_locations,
            :populations    => {},
            :rarity         => rarity
        }
    end

    def unit_moves(unit, src, dst)
        type = unit.get_type
        if src
            unless @groups[type][:populations][src]
                raise(NoMatchError, "No population of #{type} found at #{src}")
            end
            @groups[type][:populations][src] -= 1
            @groups[type][:populations].delete(src) if @groups[type][:populations][src] == 0
        end

        if dst
            @groups[type][:populations][dst] ||= 0
            @groups[type][:populations][dst] += 1
        end

        if unit.uses?(Karmic) && unit.name
            unit_name = hash_name(unit.name)
            if dst
                @named[unit_name] = dst
            else
                @named.delete(unit_name)
            end
        end
    end

    def hash_name(name)
        name.downcase.to_sym
    end
end
