require './util/log'

module Karmic
    class << self
        def at_creation(instance, params)
            instance.set_name(params[:name]) if params[:name]
            # TODO - Create a notoriety table
            instance.set_notoriety(params[:notoriety] || :unknown)
            instance.class_info[:factions].each do |faction|
                # TODO - Store interesting information about the standing of this object in the factions given
                instance.add_faction(faction, nil)
            end
        end

        def listens_for(i); [:unit_killed,:object_destroyed]; end
        def at_message(instance, message)
            case message.type
            when :unit_killed,:object_destroyed
                return unless message.has_param?(:agent) && message.agent == instance
                if message.target.is_type?(:body)
                    # FIXME - We want to store more than the name of the kill here
                    # Suggestions - notoriety / difficulty of kill, type of monster
                    instance.add_kill(message.target)
                    Log.info("#{instance.monicker} increases their notoriety by shedding the blood of #{message.target.monicker} (now has #{instance.kills.size} kills)")
                #else
                    #Log.info("#{instance.monicker} cannot become notorious for killing a mere #{message.target.monicker}")
                end
            end
        end

        def at_destruction(instance, destruction, vaporize)
            return if vaporize

            # FIXME - Create a notoriety table
            #if instance.notoriety >= :well_known
                Log.info("The great #{instance.monicker} has been utterly destroyed!")
            #end
        end

        def pack(instance)
            {
                :name      => instance.name,
                :notoriety => instance.notoriety,
                :kills     => instance.kills,
                :titles    => instance.titles,
                :deeds     => instance.deeds,
                :factions  => instance.factions
            }
        end

        def unpack(core, instance, raw_data)
            [:name, :notoriety, :kills, :titles, :deeds, :factions].each do |key|
                raise(MissingProperty, "Karmic data corrupted - #{key.inspect} data missing") unless raw_data.has_key?(key)
            end
            instance.set_name(raw_data[:name])
            instance.set_notoriety(raw_data[:notoriety])
            instance.set_kills(raw_data[:kills])
            instance.set_titles(raw_data[:titles])
            instance.set_deeds(raw_data[:deeds])
            instance.set_factions(raw_data[:factions])
        end
    end

    def name; @name; end
    def set_name(name)
        raise(ArgumentError, "No name given when setting name") unless name
        Message.dispatch(@core, :unit_renamed, {:agent => self, :old_name => @name, :name => name})
        @name = name
    end

    def notoriety; @notoriety; end
    def set_notoriety(value); @notoriety = value; end

    def kills; @kills ||= []; end
    def add_kill(target)
        # TODO - Consider adding a UID here
        kills << target.monicker
    end
    def set_kills(value); @kills = value; end

    def deeds; @deeds ||= []; end
    def add_deed(deed)
        raise(NotImplementedError, "Adding deeds is not supported")
    end
    def set_deeds(value); @deeds = value; end

    def titles; @titles ||= []; end
    def add_title(title); titles << title; end
    def set_titles(value); @titles = value; end

    def factions; @factions ||= {}; end
    def add_faction(faction, info)
        Log.debug("Adding #{monicker} to #{faction} faction", 8)
        factions[faction] = info
    end
    def set_factions(value); @factions = value; end
end
