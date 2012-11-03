require 'util'

class Portal < TypedConstructor
    attr_reader :hidden, :fortified, :oneway, :source, :dest, :owner, :wrongway
    def initialize(source, dest, owner, specials)
        type = super() do |k,v|
            (k == :special) ? (v == specials) : nil
        end

        @source    = source
        @dest   = dest

        # This matters for who is permitted to enter fortified doors / see hidden doors
        @owner  = owner

        if type[:special]
            (special = [type[:special]]) unless Array === type[:special]
            special.each do |tag|
                puts "Setting special attribute #{tag.to_s}"
                instance_variable_set("@#{tag.to_s}", true)
            end
        end

        self
    end

    def invert!
        @source,@dest=[@dest,@source]
        if @oneway
            @oneway = nil
            @wrongway = true
        end
        self
    end

    def inverse
        dup.invert!
    end
end

Portal.describe({
    :name        => "Secret Trapdoor",
    :description => "some creaky boards covered with moss",
    :special     => :hidden
})

Portal.describe({
    :name        => "Escape Tunnel",
    :description => "a small hole leading to a slippery chute",
    :special     => :oneway
})

Portal.describe({
    :name        => "Portcullis",
    :description => "an gate comprised of iron spikes",
    :special     => :fortified
})

Portal.describe({
    :name        => "Cloth Curtain",
    :description => "a ceremonial curtain decorated with fish and yen"
})

Portal.describe({
    :name        => "Hidden Crawlspace",
    :description => "a small tunnel not easily noticed or accessed",
    :special     => :hidden
})

Portal.describe({
    :name        => "Circular Arch",
    :description => "an ornate archway whose shape mimics the rising sun",
})

Portal.describe({
    :name        => "Sliding Paper Panel",
    :description => "a thin panel which slides snappily to one side",
})

Portal.describe({
    :name        => "Drop Shaft",
    :description => "a thin, narrow shaft used to drop in on unsuspecting enemies...or away from unexpected attackers",
    :special     => :oneway
})

Portal.describe({
    :name        => "Heavy Wooden Door",
    :description => "a heavy door and frame constructed of fine imported oak",
    :special     => :fortified
})

Portal.describe({
    :name        => "Shimmering Doorway",
    :description => "a door powered by some sort of magic which conveys the user to his destination...but not back",
    :special     => :oneway
})
