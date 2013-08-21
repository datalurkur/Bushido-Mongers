class Lexicon
	class Lexeme
		# In Linguistics-speak, the primary key of the lexeme; e.g. the
		# infinitive form of the verb.
		attr_reader :lemma, :types, :args

		def initialize(lemma, l_type, args = {})
			@lemma = lemma
			@types = Array(l_type)
			@args  = args
		end

		def add_type(l_type)
			@types += Array(l_type)
		end

		def add_args(args)
			@args.merge!(args)
		end
	end

	class DefaultConjugation
		def self.verb_form(state)
		end
	end

	class VerbLexeme
		# For example, the lexeme run has a present
		# third person singular form runs, a present non-third-person singular
		# form run (which also functions as the past participle and non-finite
		# form), a past form ran, and a present participle running.
		attr_accessor :state_args

		def initialize(lemma, args = {})
			@state_args &&= args[:state_args]
			@lemma = lemma
			# state_args are expected in { State => :word_form }, and are
			# intended for 'special' conjugations only.
			@state_args = state_args
		end

		def verb_form(state)
			# Hit! For special cases 
			return @state_args[state] if @state_args[state]
		end
	end
end