# TODO - add info on acceptable/used arguments to generators

module Words
    def self.generate(args)
        case args[:command]
        when :inspect
            target = args[:target]
            case target[:type]
            when :room
                return Words.describe_room(args)
            else
                if target[:is_type].include?(:corporeal)
                    return Words.describe_corporeal(target)
                elsif target[:is_type].include?(:composition_root)
                    return Words.describe_composition(target)
                elsif target[:is_type].include?(:item)
                    return Words.gen_sentence(args)
                else
                    return "I don't know how to describe a #{target[:type].inspect}, bother zphobic to fix this"
                end
            end
        when :move
            return Words.describe_room(args)
        when :attack, :get, :drop, :hide, :unhide, :equip, :unequip
            return Words.gen_sentence(args)
        when :stats
            return Words.describe_stats(args)
        when :help
            return Words.describe_help(args)
        else
            return "I don't know how to express the results of a(n) #{args[:command]}, pester zphobic to work on this"
        end
    end

    # TODO - action descriptors: The generic ninja generically slices the goat with genericness.
    def self.gen_sentence(args = {})
        to_print = args.dup
        to_print.delete(:agent)
        Log.debug(to_print, 8)

        args[:state] ||= State.new

        subject = args[:subject] || args[:agent]
        verb    = args[:verb] || args[:action] || args[:command]

        # Subject is you in second person
        if !subject && args[:state].person == :second
            subject = :you
        end

        # Second person if subject is you
        if subject == :you || (Hash === subject && subject[:monicker] == :you)
            args[:state].person = :second
        end

        # active is the default; otherwise, swap the subject/D.O.
        if args[:state].voice == :passive
            subject, args[:target] = args[:target], subject
        end

        # If subject is plural and person isn't, adjust the person
        if Array === subject && subject.size > 1
            args[:state].plural_person!
        end

        raise unless verb

        # Use an associated verb, if any exist.
        associated_verbs = Words.db.get_related_words(verb.to_sym)
        if associated_verbs && associated_verbs.size > 1
            verb = associated_verbs.rand
        end

        subject_np = Sentence::NounPhrase.new(subject)
        verb_np    = Sentence::VerbPhrase.new(verb, args)

        Sentence.new(subject_np, verb_np).to_s
    end

    def self.describe_attack(args = {})
        # TODO - reach into result_hash and pick verb
        args[:action] = :attack
        args[:agent]  = args[:attacker]
        args[:target] = args[:defender]

        Log.debug(args[:result_hash].keys)
        sentences = [gen_sentence(args)]#, gen_sentence(args[:result_hash])]
        sentences.join(" ")
    end

    private
    def self.possessor_info(possessor)
        # defaults
        person = :third
        gender = :inanimate
        # specifics
        person = :second if possessor[:monicker] == :you
        gender = possessor[:gender] if possessor[:gender]
        { :person => person, :gender => gender }
    end
    public

    def self.describe_corporeal(corporeal)
        # Describe the corporeal body
        body = corporeal[:properties][:incidental].first
        corporeal[:definite] = true
        sentences = [gen_sentence(:subject => corporeal, :verb => :have, :target => body)]
        body[:possessor_info] = possessor_info(corporeal)
        sentences << describe_composition(body)

        # TODO - Add more information about abilities, features, etc.

        sentences.join(" ")
    end

    def self.describe_stats(args)
        stats = args[:target]
        attributes = stats.first
        skills     = stats.last

        sentences = []

        stats.each do |list|
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

    def self.describe_composition(composition)
        state = State.new
        # Description is a currently-progressing state, so passive progressive.
        # verb == :grasp => "is grasped by"
        state.voice  = :passive
        state.aspect = :progressive

        sentences = []

        comp_types = {
            :attach => composition[:properties][:external],
            :wear   => composition[:properties][:worn],
            :grasp  => composition[:properties][:grasped],
        }

        comp_types.each do |verb, list|
            if list && !list.empty?
                list.each do |part|
                    part[:possessor_info] = composition[:possessor_info]
                end
                sentences << gen_sentence(
                                :subject => composition,
                                :verb    => verb,
                                :target  => list.dup,
                                :state   => state)
                sentences += list.collect do |part|
                    if part[:is_type].include?(:composition_root)
                        describe_composition(part)
                    else
                        gen_copula(:subject => part)
                    end
                end
            end
        end

        sentences.flatten.join(" ")
    end

    # TODO - Still not a proper copula.
    def self.gen_copula(args = {})
        unless args[:subject] || args[:agent]
            args[:subject] = :it
        end
        unless args[:verb] || args[:action] || args[:command]
            args[:verb]    = :be
        end

        adjectives = Sentence::Adjective.descriptor_adjectives(args[:subject])
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
        sentences = [self.gen_sentence(args)]

        args.delete(:verb)
        args.delete(:action)
        args.delete(:command)

        room = args[:target] || args[:destination]
        args.delete(:target)
        args.delete(:destination)

        args.merge!(:verb => :see)

        objects = room[:objects]
        if objects && !objects.empty?
            sentences << Words.gen_sentence(args.merge(:target => objects))
        end

        exits   = room[:exits]
        if exits && !exits.empty?
            sentences << Words.gen_sentence(args.merge(:target => Sentence::Noun.new("exits to #{Sentence::NounPhrase.new(exits)}")))
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
