class Interface
    def prompt_when_current?; !@no_prompt; end

    module NumericChoices
        def self.find_key_for(name,keys); (keys.size+1).to_s; end
        def self.decorate_name(name,key); "(#{key}) #{name}"; end
        def self.construct_prompt(hash,order); order.collect { |k| hash[k][:decorated_name] }.join(" | "); end
    end

    module LetterInNameChoices
        def self.find_key_for(name,keys)
            index = 0
            while (index < name.length) && (keys.include?(name[index,1].downcase)); index += 1; end
            key = if keys.include?(name[index,1].downcase)
                (("a".."z").to_a - keys).select_random
            else
                name[index,1].downcase
            end
            raise "Unable to find unique key for #{name}" unless key
        end
        def self.decorate_name(name,key)
            index = [name.index(key),name.index(key.upcase)].compact.min
            (index ? "#{name[0...index]}[#{name[index,1]}]#{name[index+1..-1]}" : name)
        end
        def self.construct_prompt(hash,order)
            order.collect { |k| hash[k][:decorated_name] }
        end
    end

    DEFAULT_FORMAT = NumericChoices

    class ChoiceSet < Interface
        def self.check_list_sanity(list,size)
            #(raise "List must contain values") if (list.empty?)
            if size != 1
                (raise "Incorrect number of elements per item") unless (list.inject(true) { |sum,item| sum && item.size == size })
            end
        end

        # List[name] => List[name,interface]
        def self.construct_paired(items,interface,format=DEFAULT_FORMAT)
            ChoiceSet.construct_keyed_list(pair_items_with_interface(items,interface),format)
        end
        def self.pair_items_with_interface(items,interface)
            begin
                check_list_sanity(items,1)
                list = items.collect { |item| [item,interface] }
                list << ["Cancel", Proc.new { |parent,message| parent.pop_interface }]
                list
            rescue Exception => e
                debug("Unable to pair items with interface: #{e.message}")
                debug(e.backtrace)
                []
            end
        end

        # List[name,interface] => List[key,name,interface]
        def self.construct_keyed_list(list,format=DEFAULT_FORMAT)
            ChoiceSet.construct_decorated_list(key_list(list),format)
        end
        def self.key_list(list,format=DEFAULT_FORMAT)
            begin
                check_list_sanity(list,2)
                keys = []
                keyed_list = list.collect do |name,iface|
                    key = format.find_key_for(name,keys)
                    keys << key
                    [key,name,iface]
                end
                keyed_list
            rescue Exception => e
                debug("Unable to key list: #{e.message}")
                debug(e.backtrace)
                []
            end
        end

        # List[key,name,interface] => List[decorated_name,key,name,interface]
        def self.construct_decorated_list(list,format=DEFAULT_FORMAT)
            ChoiceSet.construct_mapped_list(decorate_list(list,format),format)
        end
        def self.decorate_list(list,format=DEFAULT_FORMAT)
            begin
                check_list_sanity(list,3)
                decorated_list = list.collect do |key,name,iface|
                    [format.decorate_name(name,key),key,name,iface]
                end
                decorated_list
            rescue Exception => e
                debug("Unable to decorate list: #{e.message}")
                debug(e.backtrace)
                []
            end
        end

        # List[decorated_name,key,name,interface] => Hash
        def self.construct_mapped_list(list,format=DEFAULT_FORMAT)
            hash,order = map_list(list)
            ChoiceSet.new(hash,order,format)
        end
        def self.map_list(list,extras={})
            begin
                check_list_sanity(list,4)
                hash  = {}
                order = []
                list.each do |decorated_name,key,name,iface|
                    hash[key] = {:decorated_name => decorated_name, :name => name, :interface => iface}
                    hash[key].merge!(extras[key]) if extras.has_key?(key)
                    order << key
                end
                [hash,order]
            rescue Exception => e
                debug("Unable to map list: #{e.message}")
                debug(e.backtrace)
                [{},[]]
            end
        end

        # Hash,List => ChoiceSet
        def initialize(lookup,key_order,format=DEFAULT_FORMAT)
            @lookup    = lookup
            @key_order = key_order
            @format    = format
        end

        def prompt(parent)
            @format.construct_prompt(@lookup,@key_order)
        end

        def process(parent,message)
            # Take the first character and use it as a lookup
            key = message.strip[0,1].downcase
            if @lookup.has_key?(key)
                case @lookup[key][:interface]
                when Symbol
                    parent.append_result("#{@lookup[key][:interface]} set to #{@lookup[key][:name]}")
                    parent.set_field(@lookup[key][:interface],@lookup[key][:name])
                    parent.pop_interface
                when Proc
                    # We're relying on the Proc object to do appropriate state maintenance
                    parent.instance_exec(parent,@lookup[key],&@lookup[key][:interface])
                when Interface
                    parent.push_interface(@lookup[key][:interface])
                end
            else
                parent.append_result("Invalid choice: #{key}, please retry")
            end
        end
    end

    class DynamicSet < ChoiceSet
        def initialize(list_proc,format=NumericChoices)
            @list_proc = list_proc
            super({},[],format)
        end

        def prompt(parent)
            debug("Constructing dynamic prompt for #{parent.player}",4)
            @lookup,@key_order = @list_proc.call(parent)
            super(parent)
        end
    end

    class TextField < Interface
        def initialize(field) @field=field; end
        def prompt(parent); "Enter #{@field}:"; end
        def process(parent,message)
            parent.set_field(@field,message)
            parent.pop_interface
        end
    end

    class Waiting < Interface
        def prompt(parent); "Waiting for players to join"; end
        def process(parent,message)
        end
    end

    class ReadyPending < Interface
        def initialize; @ready=false; end
        def prompt(parent); "Waiting for all players to be ready; indicate when you are ready"; end
        def process(parent,message)
            state = if message.match(/no/)
                false
            elsif message.match(/ready/)
                true
            else
                nil
            end

            unless state.nil?
                parent.append_result("You are flagged as #{state ? "" : "NOT "}ready")
                Message.send(Message::SetPlayerReady.new(parent.player,state))
            else
                parent.append_result("Unable to process response #{message.inspect}; try \"ready\" or \"not ready\"")
            end
        end
    end
end

module DefaultInterface
    def setup_interface(game)
        available_ninjas  = Ninja.list_types - game.active_ninjas
        raise "No ninjas available!" if available_ninjas.empty?
        available_castles = Castle.list_types - game.active_castles
        raise "No castles available!" if available_castles.empty?
        Interface::ChoiceSet.construct_keyed_list([
            ["Set name",      Interface::TextField.new(:player)                                                             ],
            ["Select ninja",  Interface::ChoiceSet.construct_paired(available_ninjas, :ninja)          ],
            ["Select castle", Interface::ChoiceSet.construct_paired(available_castles, :castle)       ],
            ["Join game",     Proc.new { Message.send(Message::NewPlayer.new(field(:player),field(:castle),field(:ninja))) }],
        ])
    end

    def waiting_interface
        Interface::Waiting.new
    end

    def pending_interface
        Interface::ReadyPending.new
    end

    def playing_interface(game)
        Interface::ChoiceSet.construct_keyed_list([
            ["Move ninja", Interface::DynamicSet.new(
                Proc.new { |client|
                    debug("Constructing ninja moves for #{client.player}",3)
                    portals       = game.ninja(client.player).get_moves
                    action_names  = portals.collect { |p| "#{p.name} to #{p.dest.name}" }
                    decision_proc = Proc.new { |client,choice| Message.send(Message::SetNinjaMove.new(client.player,choice[:portal])); client.pop_interface }

                    paired_list    = Interface::ChoiceSet.pair_items_with_interface(action_names, decision_proc)
                    keyed_list     = Interface::ChoiceSet.key_list(paired_list)
                    # Associate portals with keys
                    extras = {}
                    keyed_list.each do |key,name,iface|
                        index = action_names.index(name)
                        unless index.nil?
                            extras[key] = {:portal => portals[index]}
                        end
                    end
                    decorated_list = Interface::ChoiceSet.decorate_list(keyed_list)
                    Interface::ChoiceSet.map_list(decorated_list, extras)
                })
            ],
            ["Order ninja", Interface::DynamicSet.new(
                Proc.new { |client|
                    debug("Constructing ninja orders for #{client.player}",3)
                    actions       = game.ninja(client.player).get_actions
                    decision_proc = Proc.new { |client,choice| Message.send(Message::SetNinjaAction.new(client.player,choice[:name])); client.pop_interface }

                    paired_list    = Interface::ChoiceSet.pair_items_with_interface(actions, decision_proc)
                    keyed_list     = Interface::ChoiceSet.key_list(paired_list)
                    decorated_list = Interface::ChoiceSet.decorate_list(keyed_list)
                    Interface::ChoiceSet.map_list(decorated_list)
                })
            ],
            ["Finish turn", Proc.new { |client,choice| Message.send(Message::SetPlayerReady.new(client.player,true)) }]
        ])
    end
end
