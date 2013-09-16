# Generators return strings. Creators return some form of ParseTree or PTNode.

# TODO - add info on acceptable/used arguments to generators
# TODO - distinguish between adjunct and argument phrases
module Words
    def self.generate(args)
        if args[:command]
            generate_command(args)
        elsif args[:thing]
            Log.debug(args, 7)
            generate_knowledge(args)
        end
    end

    def self.generate_command(args)
        case args[:command]
        when :inspect
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
                return "I don't know how to describe a #{target[:type].inspect}, bother zphobic to fix this"
            end
        when :move
            return describe_room(args)
        when :attack, :get, :stash, :drop, :hide, :unhide, :equip, :unequip, :open, :close
            return gen_sentence(args)
        when :say
            return gen_sentence(args.merge(:verb => :say))
        when :stats
            return describe_stats(args)
        when :help
            return describe_help(args)
        else
            return "I don't know how to express the results of a(n) #{args[:command]}, pester zphobic to work on this"
        end
    end

    # Basic, stupid clause-making from the knowledge quanta triad, to be modified as appropriately for separate knowledge bits.
    def self.quanta_args(old_args)
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
                args[:material]   = recipe[:components]
            elsif args[:connector] == :have
                args[:target] = Descriptor.set_unique(args[:target])
                args[:target][:possessor_info] = possessor_info(args[:subject])
                args[:target][:monicker] = (args[:target][:monicker].to_s + ' ' + args[:value].to_s).to_sym if args[:value]
            end
        end

        return args
    end

    def self.generate_knowledge(args)
        # I know <clause>!
        # I know that <is_a>.
        # I know how <make>.
        if know_statement = (rand(2) == 0)
            args[:target]  = DependentClause.new(quanta_args(args))
            args[:subject] = :i
            args[:verb]    = :know
            gen_sentence(args)
        else
            gen_sentence(quanta_args(args))
        end
    end

    # FIXME: Currently only does declarative.
    # Imperative is just implied-receiver, no subject.
    # Questions follow subject-auxiliary inversion
    # http://en.wikipedia.org/wiki/Subject%E2%80%93auxiliary_inversion
    def self.gen_sentence(args={})
        generate_clause(Sentence, args)
    end

    def self.generate_clause(clause_class, args={})
        clause_class.new(args).to_s
    end

    def self.describe_attack(args = {})
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
    def self.possessor_info(possessor)
        # defaults
        person = :third
        # specifics
        person = :second if possessor[:monicker] == :you
        { :person => person, :gender => (possessor[:gender] || :inanimate), :possessor => possessor[:monicker] }
    end
    public

    def self.describe_body(body)
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

    def self.describe_stats(args)
        stats = args[:target]
        sentences = []

        stats.each do |list|
            list.map! do |s|
                case s
                when BushidoObject, Room; Descriptor.describe(s, args[:agent])
                else s
                end
            end
            list.each do |stat|
                stat[:possessor] = args[:agent]
            end
            sentences << gen_sentence(
                :subject => args[:agent],
                :verb    => :have,
                :target  => list
            )
        end

        sentences.flatten.join(" ")
    end

    def self.describe_help(args)
        "Basic commands:\n"+
        args[:target].map { |c| [c, *Words.db.get_related_words(c)].join(" ") }.join("\n") + "\n"
    end

    def self.describe_container_class(composition, comp_type = :internal)
        raise unless Hash === composition

        if comp_type == :internal && !composition[:properties][:open]
            composition[:definite] = true
            return gen_copula(
                :subject    => composition,
                :adjective  => :closed
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
            gen_sentence(
                :subject  => composition,
                :verb     => composition_verbs[comp_type],
                :target   => (list && !list.empty? ? list : Noun.new(:nothing))
            )
        end
    end

    def self.describe_object(obj)
        obj[:complement] = NounPhrase.new(obj[:type])
        gen_copula(obj)
    end

    def self.describe_composition(composition)
        sentences = [describe_object(composition)]

        composition_verbs = {
            :external => :attach,
            :worn     => :wear,
            :grasped  => :hold
        }

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
    end

    def self.describe_whole_composition(composition)
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

    # identity - noun copula definite-noun - The cat is Garfield; the cat is my only pet.
    # class membership - noun copula noun - the cat is a feline.
    # predication - noun copula adjective
    # auxiliary - noun copula verb - The cat is sleeping (progressive); The cat is bitten by the dog (passive).
    # existence - there copula noun. "There is a cat." => "There exists a cat."?
    # location - noun copula place-phrase
    def self.gen_copula(args = {})
        create_copula(args).to_s.sentence
    end

    def self.create_copula(args)
        args[:subject] = args[:subject] || args[:agent] || :it

        if verb = args[:verb] || args[:action] || args[:command]
            args[:complement] = verb unless args[:complement]
        end

        args[:verb] = :is

        # If :complement is defined, it's assumed to be the only one.
        if args[:complement]
            args[:complements] = [Adjective.new(args[:complement])]
        else
            # Or, you know, some subset of these.
            args[:complements] = Adjective.new_for_descriptor(args[:subject]) +
                                 Array(args[:complements]) +
                                 Array(args[:adjectives]) +
                                 Array(args[:keywords])
        end

        IndependentClause.new(args)
    end

    def self.describe_room(args = {})
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
            sentences << gen_sentence(args.merge(:target => Noun.new("exits to #{NounPhrase.new(exits)}")))
        end

        sentences.join(" ")
    end

    def self.gen_area_name(args = {})
        noun    = {
                    :monicker => args[:type] || Noun.rand,
                    :adjectives => args[:keywords] || Adjective.rand,
                    :unique => true,
                  }
        name    = NounPhrase.new(noun)

        name.to_s.title
    end

    def self.random_name(args = {})
        noun    = {
                    :monicker => args[:type] || Noun.rand,
                    :adjectives => args[:keywords] || Adjective.rand,
                    :unique => true,
                  }
        name    = NounPhrase.new(noun)

        name.to_s.title
    end
end
