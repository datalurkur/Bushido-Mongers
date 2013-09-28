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
			@types = (@types + Array(l_type)).uniq
		end

		def add_args(args)
			@args.merge!(args)
		end
	end

=begin
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
=end

	# http://en.wikipedia.org/wiki/Derivation_(linguistics)
	class Derivation
		PATTERNS =
		[
			:adjective_to_noun, 	 # -ness (slow → slowness)
			:adjective_to_verb, 	 # -ise (modern → modernise) in British English or -ize (archaic → archaicize) in American English and Oxford spelling
			:adjective_to_adjective, # -ish (red → reddish)
			:adjective_to_adverb,	 # -ly (personal → personally)
			:noun_to_adjective, 	 # -al (recreation → recreational)
			:noun_to_verb,           # -fy (glory → glorify)
			:verb_to_adjective, 	 # -able (drink → drinkable)
			:verb_to_noun_abstract,  # -ance (deliver → deliverance) (Deverbal noun)
			:verb_to_noun_agent, 	 # -er (write → writer) (Agent noun)
		]

		attr_reader :pattern, :original, :derived

		def initialize(pattern, original, derived = Derivation.default_derivation(pattern, original))
			raise(ArgumentError, "Pattern must be one of #{PATTERNS.inspect}!") unless PATTERNS.include?(pattern)
			@pattern  = pattern
			raise(ArgumentError, "Precursor word is not correct part of speech: expected #{original_type}, received #{original.inspect}") unless original.types.include?(original_type)
			raise(ArgumentError, "Derived word is not correct part of speech: expected #{derived_type}, received #{derived.inspect}") unless derived.types.include?(derived_type)
			@original = original
			@derived  = derived
		end

		def self.default_derivation(pattern, original)
			derived_lemma = case pattern
			when :adjective_to_noun 	 # -ness (slow → slowness)
				original.lemma.to_s + "ness"
			when :adjective_to_verb 	 # -ise (modern → modernise) in British English or -ize (archaic → archaicize) in American English and Oxford spelling
				original.lemma.to_s + "ize"
			when :adjective_to_adjective # -ish (red → reddish)
				original.lemma.to_s + "ish"
			when :adjective_to_adverb	 # -ly (personal → personally)
				original.lemma.to_s + "ly"
			when :noun_to_adjective 	 # -al (recreation → recreational)
				original.lemma.to_s + "al"
			when :noun_to_verb           # -fy (glory → glorify)
				original.lemma.to_s + "ify"
			when :verb_to_adjective 	 # -able (drink → drinkable)
				original.lemma.to_s + "able"
			when :verb_to_noun_abstract  # -ance (deliver → deliverance) (Deverbal noun)
				original.lemma.to_s + "ance"
			when :verb_to_noun_agent 	 # -er (write → writer) (Agent noun)
				original.lemma.to_s + (original.lemma.to_s.match(/e$/) ? "r" : "er")
			end
			Lexicon::Lexeme.new(derived_lemma, derived_type(pattern))
		end

		def original_type(pattern = @pattern)
			self.class.original_type(pattern)
		end

		def derived_type(pattern = @pattern)
			self.class.derived_type(pattern)
		end

		private
		def self.lexeme_types(pattern)
			pattern.to_s.gsub(/_(agent|abstract)/, '').split("_to_").map(&:to_sym)
		end

		def self.original_type(pattern)
			self.lexeme_types(pattern).first
		end

		def self.derived_type(pattern)
			self.lexeme_types(pattern).last
		end
	end
end