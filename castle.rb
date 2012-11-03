require 'room'

class Castle < TypedConstructor
    attr_reader :owner
    def initialize(name,owner,border)
        type = super(name)
        @owner = owner
        @rooms = {}

        type[:rooms].each    { |i| add_room(i) }
        type[:passages].each { |i| add_passage(@rooms[i[0]], @rooms[i[1]], i[2] || []) }
        setup_border_rooms(border, type[:border_rooms].collect { |i| @rooms[i] })

        self
    end

    def random_room; @rooms.values[rand(@rooms.values.size)]; end

    def update
        @rooms.each { |k,v| v.update }
    end

private
    def add_room(name)
        unless @rooms[name].nil?
            raise "Duplicate room"
        end
        @rooms[name] = Room.new(name,self)
    end

    def add_passage(src, dest, specials)
        (raise "Invalid passage - rooms must exist")           unless src && dest
        (raise "A path from #{src} to #{dest} already exists") if src.path_to?(dest)
        (raise "A path from #{dest} to #{src} already exists") if dest.path_to?(src)

        portal = Portal.new(src, dest, @owner, specials)
        src.add_portal(portal)
        dest.add_portal(portal.inverse)
    end

    def setup_border_rooms(border,border_rooms)
        border_rooms.each do |room|
            add_passage(room, border, [])
        end
    end
end

Castle.describe({
    :name => "Kawaii Castle",
    :description => "a small, cute castle filled with shiny trinkets",
    :rooms => ["Gardens","Dojo","Treasury"],
    :passages => [
        ["Gardens", "Dojo"],
        ["Gardens", "Treasury", [:hidden]],
        ["Dojo", "Treasury", [:fortified]]
    ],
    :border_rooms => ["Gardens"]
})

Castle.describe({
    :name => "Kuro Castle",
    :description => "a large, sinister castle filled with death and destruction",
    :rooms => ["Gardens","Dojo","Treasury"],
    :passages => [
        ["Gardens", "Dojo"],
        ["Gardens", "Treasury", [:hidden]],
        ["Dojo", "Treasury", [:fortified]]
    ],
    :border_rooms => ["Gardens"]
})
