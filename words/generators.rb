# TODO - add info on acceptable/used arguments to generators

class Descriptor
    def self.container?(args)
        Log.debug(args)
        args[:is_type].include?(:composition_root) &&
        args[:container_contents].has_key?(:internal) &&
        args[:properties][:mutable_container_classes].include?(:internal)
    end
end

module Words
    def self.generate(args)
        case args[:command]
        when :inspect
            target = args[:target]
            location = args[:location]
            if location
                if Descriptor.container?(location)
                    return describe_container_class(location)
                else
                    return describe_composition_root(location)
                end
            elsif target[:is_type].include?(:room)
                return describe_room(args)
            elsif target[:is_type].include?(:corporeal)
                return describe_corporeal(target)
            elsif target[:is_type].include?(:composition_root)
                return describe_composition_root(target)
            elsif target[:is_type].include?(:item)
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

    # TODO - action descriptors: The generic ninja generically slices the goat with genericness.
    def self.gen_sentence(args = {})
        to_print = args.dup
        to_print.delete(:agent)
        Log.debug(to_print, 7)

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
        unless [:say].include?(verb)
            associated_verbs = Words.db.get_related_words(verb.to_sym)
            if associated_verbs && associated_verbs.size > 1
                verb = associated_verbs.rand
            end
        end

        subject_np = Sentence::NounPhrase.new(subject)
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
        { :person => person, :gender => (possessor[:gender] || :inanimate) }
    end
    public

    def self.describe_corporeal(corporeal)
        # Describe the corporeal body
        body = corporeal[:container_contents][:incidental].first
        corporeal[:definite] = true
        sentences = [gen_sentence(:subject => corporeal, :verb => :have, :target => body)]
        body[:possessor_info] = possessor_info(corporeal)
        sentences << describe_composition_root(body)

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

    def self.describe_container_class(composition, klass = :internal)
        list = composition[:container_contents][klass]

        gen_copula(
            :subject   => (list && !list.empty? ? list : :nothing),
            :location  => composition
        )
    end

    def self.describe_composition_root(composition)
        sentences = []

        comp_types = {
            :attach => composition[:container_contents][:external],
            :wear   => composition[:container_contents][:worn],
            :grasp  => composition[:container_contents][:grasped],
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
                                # Currently-progressing state, so passive progressive.
                                :state   => State.new(:passive, :progressive))
                sentences += list.collect do |part|
                    if part[:is_type].include?(:composition_root)
                        describe_composition_root(part)
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
