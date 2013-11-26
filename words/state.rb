module Words
    # http://en.wikipedia.org/wiki/English_verbs#Syntactic_constructions
    # http://en.wikipedia.org/wiki/English_clause_syntax

    # TODO - distinguish between patient (action receiver) and direct object (part of sentence), Useful for passive case?
    # Aspect descriptions: actions that are processes (bhāva), from those where the action is considered as a completed whole (mūrta). This is the key distinction between the imperfective and perfective.
    # further :aspects => [:inchoative,  # starting a state (not really used in English)
    #                      :prospective, # describing an event that occurs subsequent to a given reference time
    #                      :gnomic,      # for aphorisms. Similar to :habitual, doesn't usually use articles.
    #
    # http://en.wikipedia.org/wiki/Irrealis_mood
    # http://en.wikipedia.org/wiki/Subjunctive_mood
    # The form of the subjunctive is distinguishable from the indicative in five circumstances:
    # in the third person singular of any verb in the present form;
    # in all instances of the verb "be" in the present form;
    # in the first and third persons singular of the verb "be" in the past form;
    # in all instances of all verbs in the future form; and
    # in all instances of all verbs in the present negative form.

    # Other aspects:
    # http://en.wikipedia.org/wiki/Lexical_aspect

    # Implicit verb state:
    # stative: declaring a state
    # There are several subcategories of stative, that sometimes follow different prepositional rules:
    # verbs denoting sensations (feel, hear)
    # verbs denoting reasoning and mental attitude (believe, understand)
    # verbs denoting positions/stance (lie, surround)
    # verbs denoting relations (resemble, contain)
    # -OR-
    # dynamic: action

    # inchoative - starting a state

    # Mood

    class State
        FIELDS = {
            :aspect  => [:perfect,     # expressing completed action
                         :progressive, # e.g. is progressing, is happening, is missing
                         :imperfect,   # continuing or repeated event or state
                         :habitual,    # regular activity
                        ],
            :tense   => [:present, :past, :future],
            :mood    => [:indicative, :subjunctive, :imperative],
            :person  => [:first, :second, :third, :first_plural, :second_plural, :third_plural],
            :voice   => [:active, :passive],
        }

        attr_accessor :aspect, :tense, :mood, :person, :voice

        # properties => e.g. [:perfect, :present, :passive]
        def initialize(*properties)
            set_default_state
            properties.each do |prop|
                FIELDS.each do |field, list|
                    if list.include?(prop)
                        self.send("#{field}=", prop)
                    end
                end
            end
        end

        def set_default_state
            @aspect = :stative
            @tense  = :present
            @mood   = :indicative
            @person = :third
            @voice  = :active

            @unique_objects = []
        end

        def with_person(person)
            other = self.dup
            if FIELDS[:person].include?(person)
                other.person = person
            else
                raise(StandardError, "Not a person type: #{person}.")
            end
            other
        end

        def self.plural_person(person)
            index = FIELDS[:person].index(person)
            case index
            when 0, 1, 2
                FIELDS[:person][ index + 3 ]
            when 3, 4, 5
                raise StandardError
                person
            else
                raise(StandardError, "Not a person type: #{person}.")
            end
        end

        def plural_person!
            self.person = State.plural_person(self.person)
        end

        # Mark certain discrete objects for uniqueness, which determines definiteness.
        def add_unique_object(object)
            @unique_objects << object
        end

        def del_unique_object(object)
            @unique_objects.delete(object)
        end

        def unique_object?(object)
            @unique_objects.include?(object)
        end

        # State is used in hashes.

        def eql?(other)
            raise(NotImplementedError, "Can't compare word state to #{other.class}.") unless other.is_a?(State)
            FIELDS.each do |field, list|
                return false if (self.send(field) != other.send(field) && !(self.send(field).nil? || other.send(field).nil?))
            end
            return true
        end

        def hash
            [@aspect, @tense, @mood, @person, @voice].hash
        end
    end
end