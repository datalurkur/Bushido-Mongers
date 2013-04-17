# TODO - add info on acceptable/used arguments to generators

module Words
    def self.generate(args)
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

    # FIXME: Currently only does declarative.
    def self.gen_sentence(args = {})
        to_print = args.dup
        to_print.delete(:agent)
        Log.debug(to_print, 7)

        args[:state] ||= State.new

        subject = args[:subject] || args[:agent]
        verb    = args[:verb] || args[:action] || args[:command]

        # active is the default; otherwise, swap the subject/D.O.
        if args[:state].voice == :passive
            subject, args[:target] = args[:target], subject
        end

        # Subject is you in second person
        if !subject && args[:state].person == :second
            subject = :you
        end

        # Second person if subject is you
        if subject == :you || (Hash === subject && subject[:monicker] == :you)
            args[:state].person = :second
        end

        # If subject is plural and person isn't, adjust the person
        if Array === subject && subject.size > 1
            args[:state].plural_person!
        end

        raise unless verb

        # Use an associated verb, if any exist.
        unless [:say].include?(verb)
            associated_verbs = Words.db.get_related_words(verb.to_sym)
            if associated_verbs && associated_verbs.size > 1
                verb = args[:verb] = associated_verbs.rand
            end
        end

        subject_np = Sentence::NounPhrase.new(subject, args)
        verb_np    = Sentence::VerbPhrase.new(verb, args)

        sentence = Sentence.new(subject_np, verb_np)
        Log.debug(sentence, 7)
        sentence.to_s
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
        body[:definite] = true
        body[:possessor_info] = possessor_info(body)

        target_body = Marshal.load(Marshal.dump(body))
        target_body[:properties][:adjectives] ||= []
        target_body[:properties][:adjectives] << body[:type]
        target_body[:monicker] = body[:part_name] if body[:part_name]
        target_body[:definite] = false

        sentences  = [gen_sentence(:subject => body, :verb => :have, :target => target_body)]
        sentences += [describe_whole_composition(body)]

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

    # Yeah, I don't want to auto-generate this info.
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
                :subject   => (list && !list.empty? ? list : Sentence::Noun.new(:nothing)),
                :location  => composition
            )
        else
            composition[:definite] = true
            gen_sentence(
                :subject  => composition,
                :verb     => composition_verbs[comp_type],
                :target   => (list && !list.empty? ? list : Sentence::Noun.new(:nothing))
            )
        end
    end

    def self.describe_object(obj)
        obj[:complement] = Sentence::NounPhrase.new(obj[:type])
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

        # FIXME: Here is where we can interpolate the lists and e.g. pluralize where appropriate.

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

    def self.gen_copula(args = {})
        unless args[:subject] || args[:agent]
            args[:subject] = :it
        end
        unless args[:verb] || args[:action] || args[:command]
            args[:verb]    = :be
        end

        adjectives = Sentence::Adjective.new_for_descriptor(args[:subject])
        args[:subject_complement] = adjectives + [:adjective, :adjectives, :complement, :keywords].inject([]) { |a, s| a + Array(args[s]) }

        # TODO - Use expletive / inverted copula construction
        # TODO - expletive more often for second person
#        if Chance.take(:coin_toss)
            # <Agent> <verbs> <target>
            self.gen_sentence(args)
#        else
            # passive: <target> is <verbed> <preposition <Agent>>
#        end
    end

    def self.describe_room(args = {})
        sentences = [gen_sentence(args)]

        room = args[:target] || args[:destination]
        args.delete(:target)
        args.delete(:destination)

        args.delete(:verb)
        args.delete(:action)
        args.delete(:command)

        # FIXME - Use available senses.
        args.merge!(:verb => :see)

        objects = room[:objects]
        if objects && !objects.empty?
            sentences << gen_sentence(args.merge(:target => objects))
        end

        exits   = room[:exits]
        if exits && !exits.empty?
            sentences << gen_sentence(args.merge(:target => Sentence::Noun.new("exits to #{Sentence::NounPhrase.new(exits)}")))
        end

        sentences.join(" ")
    end

    def self.gen_area_name(args = {})
        noun    = { :monicker => args[:type], :adjectives => args[:keywords], :definite => true }
        name    = Sentence::NounPhrase.new(noun)
#        descriptor = db.get_keyword_words(:abstract, :noun).rand

        name.to_s.title
    end
end
