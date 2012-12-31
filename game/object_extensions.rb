Dir.glob("game/object_extensions/*") do |file|
    require file
end