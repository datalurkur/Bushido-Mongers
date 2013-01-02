require 'world/zone_template'

ZoneTemplate.define(:sanctuary,
    :depth_range     => 1..3,
    :may_contain     => [:tavern, :inn],
    :never_contains  => [:dungeon],
    :always_spawns   => [:peacekeeper],
    :may_spawn       => [:merchant],
    :never_spawns    => [:monster],
    :keywords        => [:peaceful, :outside]
)

ZoneTemplate.define(:tavern
)

ZoneTemplate.define(:inn
)

ZoneTemplate.define(:meadow,
    :depth_range   => 0..3,
    :keywords      => [:grassy, :outside],
    :always_spawns => [:monster]
)

ZoneTemplate.define(:castle,
    :depth_range     => 0..4,
    :always_contains => [:barracks, :portcullis],
    :may_contain     => [:sewer, :tower, :dungeon],
    :never_contains  => [:mountain],
    :keywords        => [:constructed, :inside],
    :optional_keywords => [:dank, :inhabited],
    :always_spawns   => [:monster]
)

ZoneTemplate.define(:barracks,
    :depth_range     => 0..0,
    :may_contain     => [:sewer, :tower, :dungeon],
    :never_contains  => [:mountain, :castle],
    :keywords        => [:constructed, :inside],
    :always_spawns   => [:monster]
)

ZoneTemplate.define(:sewer,
    :depth_range    => 0..2,
    :keywords       => [:dank, :wet, :inside],
    :always_spawns  => [:monster]
)

ZoneTemplate.define(:dock,
    :depth_range     => 1..1,
    :always_contains => [:pier],
    :may_contain     => [:boat],
    :keywords        => [],
    :always_spawns   => [:monster]
)

ZoneTemplate.define(:boat,
    :depth_range    => 0..1,
#    :req_parents    => [:dock], # unused
    :keywords       => [:wet],
    :always_spawns  => [:monster]
)

# Soon...
=begin
ZoneTemplate.define(:temple_that_serves_as_the_final_bastion_of_light_in_an_otherwise_evil_forest, {:keywords=>[], :depth_range=>1..3})
ZoneTemplate.define(:temple)
ZoneTemplate.define(:barracks)
ZoneTemplate.define(:portcullis)
ZoneTemplate.define(:tower)
ZoneTemplate.define(:dungeon)
ZoneTemplate.define(:mountain)
=end