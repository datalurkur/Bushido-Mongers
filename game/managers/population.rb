require './game/managers/manager'
require './util/packer'

# TODO
#   - Listen for death messages and adjust rarity accordingly
#   - Listen for move messages and disable spawns that have players in them (no fun in spawning things directly on top of players)
#   - Make the population manager save-/load-friendly

class PopulationManager < Manager
    include Packer
    def self.packable; [:named, :groups, :disabled_spawns]; end
    def self.unpack(core, hash)
        self.new(core).unpack(hash)
    end

    def listens_for; [:tick,:unit_animated,:unit_moves,:unit_moved,:unit_killed,:unit_renamed]; end

    def setup
        Log.debug("Population manager setting up")
        @named           = {}
        @groups          = {}
        @disabled_spawns = []

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
            spawn
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

    def each(&block)
        @groups.each do |type|
            yield(type)
        end
    end

    def spawns_for(type)
        @groups[type][:spawns]
    end

    def locate(type_or_name)
        if @groups[type_or_name]
            h = {}
            @groups[type_or_name][:populations].each do |loc_uid, num|
                h[@core.lookup(loc_uid)] = num
            end
            return h
        else
            name = hash_name(type_or_name)
            if @named[name]
                return {@core.lookup(@named[name]) => 1}
            else
                return {}
            end
        end
    end
    def enable_spawn(location)
        @disabled_spawns.delete(location.uid)
    end
    def disable_spawn(location)
        (@disabled_spawns << location.uid) unless @disabled_spawns.include?(location.uid)
    end

    def spawn
        @groups.each do |type, hash|
            unless hash[:rarity] == :extinct || hash[:rarity] == :singular
                if Rarity.roll(hash[:rarity])
                    # TODO - raws should codify how creatures reproduce
                    # TODO - Have reproduction be the deciding factor for at least some species (civilized),
                    # and follow per-pregnancy ticks, rather than a batch form like this
                    # TODO - have an off-screen/unloaded population that periodically rotates through
                    # FIXME - magic numberrrs
                    (hash[:populations].size * 0.25).floor.times do |i|
                        next if hash[:populations].size > 100
                        spawn_location_types = spawns_for(type)

                        position = nil
                        loop do
                            position   = @core.world.get_random_location(spawn_location_types)
                            position ||= @core.world.get_random_location
                            break unless @disabled_spawns.include?(position.uid)
                            count    ||= 0
                            count     += 1
                            break if count > 100
                        end

                        Log.debug("Generating #{type} in #{position.monicker}")

                        # FIXME - borrow creation arguments from a pre-existing population member
                        @core.create(type, :randomize => true, :position => position)
                    end
                end
            end
        end
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
            src_uid = src.uid
            unless @groups[type][:populations][src_uid]
                raise(NoMatchError, "No population of #{type} found at #{src}")
            end
            @groups[type][:populations][src_uid] -= 1
            @groups[type][:populations].delete(src_uid) if @groups[type][:populations][src_uid] == 0
        end

        if dst
            dst_uid = dst.uid
            @groups[type][:populations][dst_uid] ||= 0
            @groups[type][:populations][dst_uid] += 1
        end

        if unit.uses?(Karmic) && unit.name
            unit_name = hash_name(unit.name)
            if dst
                @named[unit_name] = dst.uid
            else
                @named.delete(unit_name)
            end
        end
    end

    def hash_name(name)
        name.downcase.to_sym
    end
end
