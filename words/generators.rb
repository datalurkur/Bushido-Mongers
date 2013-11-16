    # Generators return strings. Creators return some form of ParseTree or PTNode.

# TODO - add info on acceptable/used arguments to generators
# TODO - distinguish between adjunct and argument phrases
module Words
    def generate(args)
        if args[:command]
            generate_command(args)
        elsif args[:thing]
            Log.debug(args, 7)
            generate_knowledge(args)
        end
    end

    def generate_command(args)
        case args[:command]
        # TODO: Separate behavior for inspect command, with more info
        when :look, :inspect
            target = args[:target]
            location = args[:location]
            if location && location.uses?(Composition)
                return describe_composition(location)
            elsif target.is_a?(Room)
                return describe_room(args)
            elsif target.matches(:type => :body)
                return describe_body(target)
            elsif target.uses?(Composition)
                return describe_composition(target)
            elsif target.is_a?(BushidoObjectBase)
                return gen_sentence(args)
            else
                return "I don't know how to describe a #{target[:type].inspect}"
            end
        when :move
            return describe_room(args)
        when :attack, :get, :stash, :drop, :hide, :unhide, :equip, :unequip, :open, :close, :consume
            return gen_sentence(args)
        when :say, :craft, :ask
            return gen_sentence(args.merge(:verb => args[:command]))
        when :stats, :help
            return describe_list(args)
        when :inventory
            return describe_inventory(args[:agent])
        else
            Log.debug(["UNKNOWN COMMAND", args[:command], args.keys])
            return gen_sentence(args)
        end
    end

    # Basic, stupid clause-making from the knowledge quanta triad, to be modified as appropriately for separate knowledge bits.
    def quanta_args(old_args)
        args = old_args.dup
        args[:subject] = args[:thing]
        args[:verb]    = args[:connector]
        args[:target]  = args[:property]

        # Raw DB gets passed in by the object_extension method conversation::talk_about_knowledge.
        # This should only happen server-side.
        if args[:db]
            # Extrapolate and describe the recipe.
            if args[:property] == :recipe
                recipes = args[:db].raw_info_for(args[:thing])[:class_values][:recipes]
                recipe  = recipes.rand

                args[:subject]    = (rand(2) == 0) ? :i : :you
                args[:target]     = args[:thing]
                args[:components] = recipe[:components]
            elsif args[:connector] == :have
                args[:state] ||= State.new
                args[:state].add_unique_object(args[:target])
                args[:target][:possessor_info] = possessor_info(args[:subject])
                args[:target][:monicker] = (args[:target][:monicker].to_s + ' ' + args[:value].to_s).to_sym if args[:value]
            end
        end

        return args
    end

    def generate_knowledge(args)
        # I know <clause>!
        # I know that <is_a>.
        # I know how <make>.
        if know_statement = (rand(2) == 0)
            args[:target]  = DependentClause.new(self, quanta_args(args))
            args[:subject] = :i
            args[:verb]    = :know
            gen_sentence(args)
        else
            gen_sentence(quanta_args(args))
        end
    end

    def describe_attack(args = {})
        args[:action] = :attack
        args[:agent]  = args[:attacker]
        args[:target] = args[:defender]

        if args[:result_hash][:subtarget]
            args[:defender][:subtarget] = args[:result_hash][:subtarget]
        end

        case args[:result_hash][:damage_type]
        when :piercing
            args[:verb] = :slice
        when :blunt
            args[:verb] = :bash
        when :nonlethal
            # TODO - How should we describe this? Default to :attack...
        when nil
            # An improvised attack is probably just going to wack the item into the target, unless the item is bladed somehow.
            args[:verb] = :bash
        end

        sentences = [gen_sentence(args.merge(args[:result_hash]))]
        sentences.join(" ")
    end

    private
    def possessor_info(possessor)
        # defaults
        person = :third
        # specifics
        person = :second if possessor[:monicker] == :you
        { :person => person, :gender => (possessor[:gender] || :inanimate), :possessor => possessor[:monicker] }
    end
    public

    def describe_body(body)
        state = State.new(:progressive)
        state.add_unique_object(body)

#        body[:possessor_info] = possessor_info(body)

        sentences = []
        missing_parts = body.atypical_body(:missing)
        if missing_parts.empty?
            sentences << gen_sentence(:subject => body, :verb => :have, :target => "normal #{body.get_type} body")
        else
            sentences << gen_sentence(:subject => body, :verb => :have, :target => "#{body.get_type} body")
            sentences << gen_sentence(:subject => body,
                                      :verb    => :miss,
                                      :target  => missing_parts,
                                      :state   => state)
        end

        # TODO - Add more information about abilities, features, etc.

        sentences.join(" ")
    end

    def assign_possessor_to_list(possessor, list)
        list.each do |entry|
            entry[:possessor] = possessor
        end
    end

    def describe_list(args)
#        Log.debug(args[:list])
        list = args[:list].map { |entry| Descriptor.describe(entry, args[:observer]) }

        flat_list = false

        case args[:command]
        when :stats
            verb    = :have
            assign_possessor_to_list(args[:agent], list)
        when :help
            list.map! { |c| [c, *synonyms_of(c)].join(" ") }
            list.insert(0, "Basic commands:")
            flat_list = true
        when :inventory, :composition
            verb    = args[:verb]
            assign_possessor_to_list(args[:agent], list)
        else
            Log.warning("Invalid command #{args[:command]}?")
        end

        sentences = []
        if flat_list
            sentences << list.join("\n")
        else
            list.each do |entry|
                sentences << gen_sentence(
                    :observer => args[:observer],
                    :subject  => args[:agent],
                    :verb     => verb,
                    :target   => entry,
                    :state    => args[:state] || State.new
                )
            end
        end

        sentences.flatten.join(" ")
    end

=begin
    def describe_inventory(args)
        args[:command] = :inventory

        composition_verbs = {
            :external => :attach,
            :worn     => :wear,
            :grasped  => :hold
        }

        descriptions = []
        [:grasped, :worn].each do |location|
            list_args = args.dup
            list_args[:list] = args[location] || []
            list_args[:verb] = composition_verbs[location]
            descriptions << describe_list(list_args)
        end
        descriptions
    end

    # AddModifier(composition, :closed)
=begin
        # TODO - handle all lists in either active or passive forms.
        if rand(2) == 0
            gen_copula(
                :subject   => (list && !list.empty? ? list : Noun.new(:nothing)),
                :location  => composition # FIXME - LocationPhrase
            )
        else
            composition[:unique] = true
            gen_copula(
                :subject  => composition,
                :verb     => composition_verbs[comp_type],
                :target   => (list && !list.empty? ? list : Noun.new(:nothing))
            )
        end
=end

    def describe_inventory(agent)
        return unless agent.uses?(Corporeal)
        [:grasped, :worn].collect do |klass|
            agent.external_body_parts.collect { |bp| describe_composition_klass(bp, klass) }.compact.join(" ")
        end.flatten.compact
#        [describe_composition_klass(agent, :grasped), describe_composition_klass(agent, :worn)].compact
    end

    def describe_composition_klass(composition, klass)
        if composition.composed_of?(klass)
            list = composition.get_contents(klass)
            list = [:nothing] if list.empty?
            return location_copula(composition, list, klass).sentence
        end
    end

    def describe_composition(composition, klasses = nil)
        unless klasses
            klasses = if composition.container?
                # AddModifier(composition, :closed)
                if !composition.open?
                    return gen_copula(
                        :subject    => composition,
                        :complement => :closed
                    )
                end
                [:internal]
            else
                [:external, :grasped, :worn]
            end
        end

        descriptions = [type_copula(composition).sentence]

        klasses.each { |klass| descriptions << describe_composition_klass(composition, klass) }
        descriptions.compact
    end

    def describe_room(args = {})
        # AddExistenceDetail(RoomType)
        # AddModifier(Room, keywords/adjectives)
        # AddExistenceDetail(observer.perceivable_objects_of(room.get_contents(:internal) - [observer]))
        # AddExistenceDetail(Exits)
        Log.debug(args, 9)
        sentences = [gen_sentence(args)]

        room = args[:target] || args[:destination]
        args.delete(:target)
        args.delete(:destination)

        args.delete(:verb)
        args.delete(:action)
        args.delete(:command)

        # FIXME - Use available senses.
        args.merge!(:verb => :see)

        if room.is_a?(Room)
            objects = args[:observer].perceivable_objects_of(room.get_contents(:internal) - [args[:observer]])
            exits   = room.connected_directions
        else
            # When sent a debug hash. Only happens in testing...
            objects = room[:objects]
            exits   = room[:exits]
        end

        if objects && !objects.empty?
            sentences << gen_sentence(args.merge(:target => objects))
        end

        if exits && !exits.empty?
            sentences << gen_sentence(args.merge(:target => Noun.new("exits to #{NounPhrase.new(self, exits)}")))
        end

        sentences.join(" ")
    end

    def gen_area_name(args = {})
        noun    = {
                    :monicker   => args[:type]     || Noun.rand(self),
                    :adjectives => args[:keywords] || Adjective.rand(self),
                  }
        state = State.new
        state.add_unique_object(noun)
        name    = Words::NounPhrase.new(self, noun, :state => state)

        name.to_s.title
    end

    def random_name(args = {})
        noun    = {
                    :monicker   => [args[:type], Noun.rand(self)].rand,
                    :adjectives => [args[:keywords], Adjective.rand(self)].rand,
                  }
        state = State.new
        state.add_unique_object(noun)
        state.add_unique_object(noun[:of_phrase])
        name    = NounPhrase.new(self, noun, :state => state)

        name.to_s.title
    end
end
