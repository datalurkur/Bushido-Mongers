require 'world/region_container'
require 'world/area'

require 'math/noise/noise'

class Zone < RegionContainer
    def initialize(name, size)
        super(name, size)
    end

    def self.test_zone
        zone = Zone.new("Test Zone", 1)
        zone.set_region(0,0,Area.test_area)
        zone
    end

    def self.zone_generation_test(w,h,scale,offset,threshold)
        require 'graphics/png'

        corridor_size = 2
        room_size = 6
        unit_size = room_size + corridor_size
        total_size = [
            (w * unit_size) + corridor_size,
            (h * unit_size) + corridor_size
        ]

        noise = Noise.new
        room_image = DerpyPNG.new(total_size[0], total_size[1])
        (0...w).each do |x|
            ax = (2*x)
            xp = (ax*scale/w) + offset
            (0...h).each do |y|
                ay = (2*y)
                yp = (ay*scale/h) + offset
                # Check for room existence
                if noise.perlin2(xp+1,yp+1) >= threshold
                    # Room exists
                    room_image.fill_box(
                        (unit_size*x)+corridor_size,
                        (unit_size*y)+corridor_size,
                        room_size, room_size, :white
                    )

                    # Check for corridor existence
                    # Top corridor
                    if noise.perlin2(xp+1,yp) >= threshold
                        room_image.fill_box(
                            (unit_size*x)+(unit_size/2),
                            (unit_size*y),
                            corridor_size, corridor_size, :white
                        )
                    end
                    # Left corridor
                    if noise.perlin2(xp,yp+1) >= threshold
                        room_image.fill_box(
                            (unit_size*x),
                            (unit_size*y)+(unit_size/2),
                            corridor_size, corridor_size, :white
                        )
                    end

                    # Right corridor
                    if x == (w-1) && noise.perlin2(xp+2,yp+1) >= threshold
                        room_image.fill_box(
                            (unit_size*(x+1)),
                            (unit_size*(y))+(unit_size/2),
                            corridor_size, corridor_size, :white
                        )
                    end

                    # Bottom corridor
                    if y == (h-1) && noise.perlin2(xp+1,yp+2) >= threshold
                        room_image.fill_box(
                            (unit_size*(x))+(unit_size/2),
                            (unit_size*(y+1)),
                            corridor_size, corridor_size, :white
                        )
                    end

                end
            end
        end
        room_image.save("room.png")
    end
end
