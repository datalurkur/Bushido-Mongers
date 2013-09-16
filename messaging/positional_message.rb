require './messaging/message_base'

class PositionalMessage < MessageBase
    class << self
        def setup(core)
            super(core)
            @positions          ||= {}
            @positions[core]      = {}
            @positions[core][nil] = []
        end

        def listener_name(listener)
            BushidoObject === listener ? "#{listener.monicker} (#{listener.uid})" : listener.class
        end

        def set_listener_position_uid(core, listener, p_uid)
            @positions[core][p_uid] ||= []
            @positions[core][p_uid] << listener unless @positions[core][p_uid].include?(listener)
        end
        def set_listener_position(core, listener, position)
            p_uid = position ? position.uid : nil
            set_listener_position_uid(core, listener, p_uid)
        end

        def clear_listener_position_uid(core, listener, p_uid)
            if @positions[core][p_uid]
                @positions[core][p_uid].delete(listener)
                @positions[core].delete(p_uid) if p_uid && @positions[core][p_uid].empty?
            end
        end
        def clear_listener_position(core, listener, position)
            p_uid = position ? position.uid : nil
            clear_listener_position_uid(core, listener, p_uid)
        end

        def change_listener_position_uid(core, listener, c_uid, p_uid)
            @positions[core][c_uid] ||= []
            @positions[core][c_uid] << listener unless @positions[core][c_uid].include?(listener)
            @positions[core][p_uid].delete(listener)
            @positions[core].delete(p_uid) if p_uid && @positions[core][p_uid].empty?
        end
        def change_listener_position(core, listener, current_position, previous_position)
            c_uid = current_position  ? current_position.uid  : nil
            p_uid = previous_position ? previous_position.uid : nil
            change_listener_position_uid(core, listener, c_uid, p_uid)
        end

        def register_listener(core, message_type, listener)
            super(core, message_type, listener)
            position = (Position === listener && listener.has_position?) ? listener.absolute_position : nil
            set_listener_position(core, listener, position)
        end

        def unregister_listener(core, message_type, listener)
            super(core, message_type, listener)
            position = (Position === listener && listener.has_position?) ? listener.absolute_position : nil
            clear_listener_position(core, listener, position)
        end

        def dispatch_positional(core, locations, type, args={}, scope=1)
            raise(NotImplementedError, "Can't search outside local scope yet") if scope != 1
            m = Message.new(type, args)

            message_class = types[type][:message_class]
            listener_list = get_listeners_at(core, locations, message_class, type)

            sent_to = []
            @listener_state_dirty.push(false)
            while (next_listener = listener_list.shift)
                next_listener.process_message(m)
                sent_to << next_listener
                if @listener_state_dirty[-1]
                    listener_list = get_listeners_at(core, locations, message_class, type) - sent_to
                end
            end
            @listener_state_dirty.pop
        end

        def get_listeners_at(core, locations, klass, type)
            locations_array = locations.inject(@positions[core][nil]) do |s,i|
                i_uid = i ? i.uid : nil
                listeners_here = @positions[core][i_uid]
                if listeners_here.nil?
                    s
                else
                    s | listeners_here
                end
            end
            locations_array & (@listeners[core][type] | @listeners[core][klass])
        end
    end
end

class DebugPositionalMessage < PositionalMessage
    class << self
        def dispatch_positional(core, locations, type, args={}, scope=1)
            locations         = Array(locations)
            klass             = types[type][:message_class]
            new_listener_list = get_listeners_at(core, locations, klass, type)
            old_listener_list = (@listeners[core][type] + @listeners[core][klass]).uniq
            old_filtered      = old_listener_list.select do |l|
                (Position === l && l.has_position? && locations.include?(l.absolute_position)) || !(Position === l)
            end

            if old_filtered.size != new_listener_list.size ||
              (old_filtered & new_listener_list).size != old_filtered.size
                Log.error(["Positional messaging is broken!", caller])
                Log.error(["Attempting to dispatch #{type} message to locations:", locations])
                Log.error(["Expected listeners:", old_filtered.size])
                old_output = old_filtered.collect do |i|
                    listener_name(i)
                end
                Log.error(["Old filtered:", old_output])
                Log.error(["Actual listeners:", new_listener_list.size])
                new_output = new_listener_list.collect do |i|
                    listener_name(i)
                end
                Log.error(["New listener list:", new_output])
            end

            super(core, locations, type, args, scope)
        end
    end
end
