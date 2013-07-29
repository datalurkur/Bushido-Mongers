IGNORED_CONNECTORS =
[
	:atomic_object,
	:effect_target
]

GROUP_KNOWLEDGE =
[
	[:object, :is, Proc.new { |odb, type| odb.ancestry_of(type) - IGNORED_CONNECTORS } ],
	[:consumable, :resolve, :hunger]
]

IDENTITIES =
[
	
]