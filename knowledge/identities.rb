IGNORED_CONNECTORS =
[
	:atomic_object,
	:effect_target,
	:can_wear,
	:civil,
	:archetype,
	:basic_attributes,
	:has_aspects
]

GROUP_KNOWLEDGE =
[
	[:object, :is, Proc.new { |odb, type| odb.ancestry_of(type) - IGNORED_CONNECTORS } ],
	[:consumable, :resolve, :hunger]
]

IDENTITIES =
[
	
]