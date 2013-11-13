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
            if location
                if location[:is_type].include?(:container)
                    return describe_container_class(location)
                else
                    return describe_composition(location)
                end
            elsif target[:is_type].include?(:room)
                return describe_room(args)
            elsif target[:is_type].include?(:body)
                return describe_body(target)
            elsif target[:is_type].include?(:container)
                # Needs to be ahead of :composition, as containers are compositions.
                return describe_container_class(target)
            elsif target[:is_type].include?(:composition)
                return describe_composition(target)
            elsif target[:is_type].include?(:object)
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
            return describe_inventory(args)
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
                args[:target] = Descriptor.set_unique(args[:target])
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
        body[:unique] = true
        body[:possessor_info] = possessor_info(body)

        sentences = []
        if body[:missing_parts].empty?
            sentences << gen_sentence(:subject => body, :verb => :have, :target => "normal #{body[:type]} body")
        else
            sentences << gen_sentence(:subject => body, :verb => :have, :target => "#{body[:type]} body")
            sentences << gen_sentence(:subject => body,
                                      :verb    => :miss,
                                      :target  => body[:missing_parts],
                                      :state   => State.new(:progressive))
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

    def describe_container_class(composition, comp_type = :internal)
        raise unless Hash === composition

        if comp_type == :internal && !composition[:properties][:open]
            composition[:definite] = true
            return gen_copula(
                :subject    => composition,
                :complement => :closed
            )
        end

        list = composition[:container_contents][comp_type]
        composition_verbs = { :internal => :contain }

        if rand(2) == 0
            gen_copula(
                :subject   => (list && !list.empty? ? list : Noun.new(:nothing)),
                :location  => composition
            )
        else
            composition[:unique] = true
            gen_copula(
                :subject  => composition,
                :verb     => composition_verbs[comp_type],
                :target   => (list && !list.empty? ? list : Noun.new(:nothing))
            )
        end
    end

    def describe_object(obj)
        gen_copula(obj.merge(:complement => NounPhrase.new(self, obj)))
    end

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

    def describe_composition(args)
        args[:command] = :composition

        composition_verbs = {
            :external => :attach,
            :worn     => :wear,
            :grasped  => :hold
        }

        #args[:state] = State.new(:progressive)

        descriptions = [describe_object(args)]
        [:external, :grasped, :worn].each do |location|
            list_args = args.dup
            list_args[:list] = args[:container_contents][location] || []
#            list_args[:list] = args[location] || []
            list_args[:subject] = :it
            list_args[:verb] = composition_verbs[location]
            descriptions << describe_list(list_args)
        end
        descriptions

=begin
        composition_verbs.keys.each do |comp_type|
            list = composition[:container_contents][comp_type]
            if list && !list.empty?
                list.each do |part|
                    part[:possessor_info] = composition[:possessor_info]
                end
                sentences << gen_sentence(
                                :subject => composition[:possessor],
                                :verb    => composition_verbs[comp_type],
                                :target  => list.dup,
                                # Currently-progressing state, so passive progressive.
                                :state   => State.new)
                sentences += list.collect do |part|
                    if part[:is_type].include?(:composition)
                        describe_composition(part)
                    else
                        gen_copula(:subject => part)
                    end
                end
            end
        end
        sentences.flatten.join(" ")
=end
    end

    def describe_whole_composition(composition)
        sentences = []#describe_object(composition)]

        composition_verbs = {
            :external => :attach,
            :worn     => :wear,
            :grasped  => :hold
        }

        search_list = [composition]
        external = []
        worn     = []
        held     = []

        while !search_list.empty?
            current_comp = search_list.shift
            composition_verbs.keys.each do |comp_type|
                list = current_comp[:container_contents][comp_type]
                if list && !list.empty?
                    # Add any compositions to the search list.
                    search_list += list.select { |p| p[:is_type].include?(:composition) }
                    # Cascade possession down.
                    list.each { |p| p[:possessor_info] = current_comp[:possessor_info] }

                    location = {
                        :monicker => current_comp[:part_name] || current_comp[:monicker],
                        :possessor_info => current_comp[:possessor_info]
                    }
                    case comp_type
                    when :external
                        external += list
                    when :worn
                        worn += list.each { |p| p[:location] = location }
                    when :grasped
                        held += list.each { |p| p[:location] = location }
                    end
                end
            end
        end

        # FIXME: Here is where we can interpolate the lists and e.g. pluralize where appropriate ("a leg and a leg" => "two legs").

        unless external.empty?
            sentences << gen_sentence(
                :subject  => composition,
                :verb     => composition_verbs[:external],
                :target   => external,
                :state    => State.new(:passive, :progressive)
            )
        end

        unless worn.empty?
            sentences << gen_sentence(
                :subject  => composition[:possessor_info][:possessor],
                :verb     => composition_verbs[:worn],
                :target   => worn,
                :state    => State.new(:progressive)
            )
        end

        unless held.empty?
            sentences << gen_sentence(
                :subject  => composition[:possessor_info][:possessor],
                :verb     => composition_verbs[:grasped],
                :target   => held,
                :state    => State.new(:progressive)
            )
        end
=begin
        comp_list.each do |comp_type, list|
            list.each do |part, part_location|
                part[:possessor_info] = part_location[:possessor_info]
                subject = part_location[:possessor_info] ? composition[:possessor_info][:possessor] : nil # And if possessor isn't defined?
                sentences << gen_sentence(
                    :subject  => composition[:possessor_info][:possessor],
                    :verb     => composition_verbs[comp_type],
                    :target   => part,
                    :location => part_location,
                    :state    => State.new(:progressive)
                )
            end
            sentences << "\n"
        end
=end

        sentences.flatten.join(" ")
    end

    def describe_room(args = {})
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

        # FIXME - In the future, these will be object IDs, and need to be looked up from a core for more information
        objects = room[:objects]
        if objects && !objects.empty?
            sentences << gen_sentence(args.merge(:target => objects))
        end

        exits   = room[:exits]
        if exits && !exits.empty?
            sentences << gen_sentence(args.merge(:target => Noun.new("exits to #{NounPhrase.new(self, exits)}")))
        end

        sentences.join(" ")
    end

    def gen_area_name(args = {})
        noun    = {
                    :monicker   => args[:type]     || Noun.rand(self),
                    :adjectives => args[:keywords] || Adjective.rand(self),
                    :unique     => true,
                  }
        name    = Words::NounPhrase.new(self, noun)

        name.to_s.title
    end

    def random_name(args = {})
        noun    = {
                    :monicker   => [args[:type], Noun.rand(self)].rand,
                    :adjectives => [args[:keywords], Adjective.rand(self)].rand,
                    :unique     => true,
                    :of_phrase  => Descriptor.set_unique(Noun.rand(self))
                  }
        name    = NounPhrase.new(self, noun)

        name.to_s.title
    end
end
