require './words/words'

class Lexicon
	class Lexeme
		# In Linguistics-speak, the primary key of the lexeme; e.g. the
		# infinitive form of the verb.
		attr_reader :lemma, :types, :args

		def initialize(lemma, l_type = [], args = {})
			@lemma = lemma.to_sym
			@types = Array(l_type)
			@args  = args
			args[:morphs] ||= {}# unless @types.include?(:morphed)
		end

		def add_type(l_type)
			@types = (@types + Array(l_type)).uniq
		end

		def add_args(args)
			@args.merge!(args)
		end

		def to_s; @lemma; end
	end

	# Sub-classes must define pattern_match?, which determines if a pattern is valid.
	# http://en.wikipedia.org/wiki/Word_formation#Types_of_word_formation
	class MorphologicalRule
		def self.sym_to_class(morph_type)
			Lexicon.const_get(morph_type.to_s.capitalize.to_sym)
		end

		# Make sure parts of speech are correct, and that the pattern is known.
		def self.check_consistency(pattern, original, morphed)
			raise(ArgumentError, "Invalid pattern #{pattern.inspect}") unless pattern_match?(pattern)
			raise(ArgumentError, "Original word is not correct part of speech: expected #{original_type(pattern)}, received #{original.inspect}") unless original.types.include?(original_type(pattern))
			raise(ArgumentError, "Morphed word is not correct part of speech: expected #{morphed_type(pattern)}, received #{morphed.inspect}") unless morphed.types.include?(morphed_type(pattern))
		end

		def self.original_type(pattern)
			expected_types(pattern).first
		end

		def self.morphed_type(pattern)
			expected_types(pattern).last
		end
	end

	# http://en.wikipedia.org/wiki/Derivation_(linguistics)
	class Derivation < MorphologicalRule
		PATTERNS =
		[
			:adjective_to_noun, 	 # -ness (slow → slowness)
			# Unlikely to be used:
			#:adjective_to_verb, 	 # -ise (modern → modernise) in British English or -ize (archaic → archaicize) in American English and Oxford spelling
			#:adjective_to_adjective, # -ish (red → reddish) (used as reducer?)
			#:verb_to_noun_abstract,  # -ance (deliver → deliverance) (Deverbal noun)
			:adjective_to_adverb,	 # -ly (personal → personally)
			#:noun_to_adjective, 	 # -al (recreation → recreational)
			:noun_to_verb,           # -fy (glory → glorify)
			:verb_to_adjective, 	 # -able (drink → drinkable)
			:verb_to_noun_agent, 	 # -er (write → writer) (Agent noun)
		]

		def self.pattern_match?(pattern)
			PATTERNS.include?(pattern)
		end

		# Operates on lexemes.
		def self.default_lexeme(db, pattern, original)
			derived_lemma = case pattern
			when :adjective_to_noun 	 # -ness (slow → slowness)
				original.lemma.to_s + "ness"
			when :adjective_to_verb 	 # -ise (modern → modernise) in British English or -ize (archaic → archaicize) in American English and Oxford spelling
				original.lemma.to_s + "ize"
			when :adjective_to_adjective # -ish (red → reddish)
				original.lemma.to_s + "ish"
			when :adjective_to_adverb	 # -ly (personal → personally)
				original.lemma.to_s.gsub(/(le)?$/, 'ly')
			when :noun_to_adjective 	 # -al (recreation → recreational)
				original.lemma.to_s + "al"
			when :noun_to_verb           # -fy (glory → glorify)
				original.lemma.to_s + "ify"
			when :verb_to_adjective 	 # -able (drink → drinkable)
				original.lemma.to_s + "able"
			when :verb_to_noun_abstract  # -ance (deliver → deliverance) (Deverbal noun)
				original.lemma.to_s + "ance"
			when :verb_to_noun_agent 	 # -er (write → writer) (Agent noun)
				original.lemma.to_s.gsub(/(e)?$/, 'er')
			else
				raise ArgumentError, "No knowledge of how to apply #{pattern} to #{original.lemma}"
			end
			morphed = Lexeme.new(derived_lemma, morphed_type(pattern), :morph_type => pattern)
			check_consistency(pattern, original, morphed)
			morphed
		end

		def self.expected_types(pattern)
			pattern.to_s.gsub(/_(agent|abstract)/, '').split("_to_").map(&:to_sym)
		end
	end

	class Inflection < MorphologicalRule
		PATTERNS =
		[
			:past_participle,
			:gerund,
			:plural
		]

		def self.pattern_match?(pattern)
			pattern.is_a?(Words::State) || PATTERNS.include?(pattern)
		end

		# Given a pattern, apply the default morphology.
		# e.g. the gerund of a standard verb is 'verb-ing'
		# Takes and returns a lexeme.
		def self.default_lexeme(db, pattern, original)
			lemma_str = original.lemma.to_s
			inflected_lemma = case pattern
			when :past_participle
				Words::Verb.conjugate(db, original.lemma, Words::State.new(:past))
            when :gerund
                # drop any ending 'e'
                lemma_str.sub!(/e$/, '')
                # Double the ending letter, if necessary.
                lemma_str += 'ing'
                lemma_str.to_sym
            when :plural
				(lemma_str + "s").to_sym
            when Words::State
	            # Regular conjugation.
	            case pattern.tense
	            when :present
	                if pattern.person == :third
	                    Words::Verb.sibilant?(lemma_str) ? "#{lemma_str}es" : "#{lemma_str}s"
	                else
	                    original.lemma
	                end
	            when :past
	                # drop any ending 'e'
	                lemma_str.sub!(/e$/, '')
	                lemma_str += 'ed'
	            when :future
	                # Future tense is handled by auxiliaries, so state_conjugate does the lifting here.
	                lemma_str
	            end
			else
				raise ArgumentError, "No knowledge of how to apply #{pattern} to #{original.lemma}"
			end

			morphed = Lexeme.new(inflected_lemma, morphed_type(pattern), :morph_type => pattern)
			check_consistency(pattern, original, morphed)
			morphed
		end

		private
		def self.expected_types(pattern)
			case pattern
			when :past_participle, :gerund, Words::State
				[:verb, :verb]
			when :plural
				[:noun, :noun]
			else
				raise ArgumentError, "pattern is #{pattern}"
			end
		end
	end

	def verify
		# Words are not in multiple sets for certain association types; synonyms in particular.
		# Warn if words contain many parts-of-speech as types.
	end
end