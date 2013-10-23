module Words
    # FIXME: Currently only does declarative.
    # Imperative is just implied-receiver, no subject.
    # Questions follow subject-auxiliary inversion
    # http://en.wikipedia.org/wiki/Subject%E2%80%93auxiliary_inversion
    def gen_sentence(args={})
        generate_clause(Sentence, args)
    end

    def generate_clause(clause_class, args={})
        clause_class.new(self, args).to_s
    end

	# identity - noun copula definite-noun - The cat is Garfield; the cat is my only pet.
    def identity_copula(args = {})
        args[:subject] = args[:subject] || args[:agent] || :it
    end
    # class membership - noun copula noun - the cat is a feline.
    # predication - noun copula adjective
    # auxiliary - noun copula verb - The cat is sleeping (progressive); The cat is bitten by the dog (passive).
    # existence - there copula noun. "There is a cat." => "There exists a cat."?
    # location - noun copula place-phrase
    def gen_copula(args = {})
        create_copula(args).to_s.sentence
    end

    def create_copula(args)
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

        IndependentClause.new(self, args)
    end

end