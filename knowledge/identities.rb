IGNORED_CONNECTORS =
[
	:atomic_object,
	:effect_target,
	:can_wear,
	:civil,
	:archetype,
	:basic_attributes,
	:aspectual
]

# This applies to the class as a whole; e.g. humans are an example of a biped class.
GROUP_KNOWLEDGE =
[
	[:object, :is, Proc.new { |odb, type| odb.ancestry_of(type) - IGNORED_CONNECTORS } ],
	[:consumable, :resolve, :hunger]
]

# These apply to individual entities; e.g. a human's name or profession.
IDENTITIES =
[
	[:self, :have, :name, Proc.new { |odb, object| object.is_a?(BushidoObjectBase) ? object.monicker : object } ]
]

=begin

intolerable_actions
	attacking of ally
	taking item with owned_by=>ally

if self=>name


if sale=>completed
	sale=>price taken from buyer
	sale=>price given to seller
=end