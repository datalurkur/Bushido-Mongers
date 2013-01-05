module Quality
    class << self
        def levels
            [
                :atrocious,
                :shoddy,
                :poor,
                :dubious,
                :substandard,
                :standard,
                :decent,
                :fine,
                :superior,
                :masterwork,
                :legendary,
            ]
        end

        def index(l)
            i = levels.index(l)
            if i.nil?
                raise "Unknown quality #{l.inspect}"
            end
            i
        end

        def value(l)
            level    = index(l)
            standard = index(:standard)
            2 ** (level - standard)
        end
    end
end

module Chance
    class << self
        def levels
            {
                :unhead_of  => 0.00001,
                :rare       => 0.001,
                :unusual    => 0.022,
                :uncommon   => 0.158,
                :coin_toss  => 0.5,
                :likely     => 0.842,
                :probable   => 0.978,
                :certain    => 0.999,
                :guaranteed => 0.99999
            }
        end

        def take(level)
            raise "Level #{level.inspect} is not a Chance!" unless levels.keys.include?(level)
            return (Kernel.rand < levels[level])
        end
    end
end

module Size
    class << self
        def levels
            [
                :miniscule,
                :tiny,
                :small,
                :medium,
                :large,
                :enormous,
                :gargantuan
            ]
        end

        def index(l)
            i = levels.index(l)
            if i.nil?
                raise "Unknown size #{l.inspect}"
            end
            i
        end

        def value(l)
            level    = index(l)
            standard = index(standard_size)
            2 ** (level - standard)
        end

        def standard_size
            :medium
        end

        def adjust(l, relative)
            offset = index(relative) - index(standard_size)
            level  = index(l)

            new_level = [[level + offset, 0].max, levels.size].min
            levels[new_level]
        end
    end
end
