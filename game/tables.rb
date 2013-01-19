module DataTables
    class << self
        def extended(klass)
            @tables ||= []
            @tables << klass
        end

        def setup
            @tables.each(&:setup)
        end
    end

    def setup
        @indices = {}
        @values  = {}
        raw_values.each_with_index do |elem, i|
            @indices[elem.first] = i
            @values[elem.first]  = elem.last
        end
        @num_values = raw_values.size
    end

    def value_of(item)
        raise "No item #{item} found in #{self.inspect}" unless @values.has_key?(item)
        @values[item]
    end

    def value_at(index)
        raise "Index out of range" if index < 0 || index >= @num_values
        raw_values[index].first
    end

    def index_of(item)
        raise "No item #{item} found in #{self.inspect}" unless @indices.has_key?(item)
        @indices[item]
    end

    def adjust(value, relative_value)
        offset       = difference(standard, relative_value)
        normal_index = index_of(value)

        new_level = [[normal_index + offset, 0].max, @num_values.size].min
        value_at(new_level)
    end

    def difference(base_value, relative_value)
        index_of(relative_value) - index_of(base_value)
    end
end

module Speed
    def self.raw_values; [
        [:glacial,   0.1],
        [:slow,      0.5],
        [:normal,    1.0],
        [:fast,      2.0],
        [:breakneck, 10.0]
    ]; end
    def self.standard; :normal; end
    extend DataTables
end

module Difficulty
    def self.raw_values; [
        [:trivial,     0.05],
        [:pedestrian,  0.1],
        [:easy,        0.2],
        [:simple,      0.3],
        [:normal,      0.4],
        [:challenging, 0.5],
        [:difficult,   0.6],
        [:demanding,   0.7],
        [:formidable,  0.9],
        [:dicey,       0.9],
        [:impossible,  1.0]
    ]; end
    def self.standard; :normal; end
    extend DataTables
end

module Quality
    def self.raw_values; [
        [:atrocious,   0.1],
        [:shoddy,      0.2],
        [:poor,        0.35],
        [:dubious,     0.5],
        [:substandard, 0.65],
        [:standard,    1.0],
        [:decent,      1.2],
        [:fine,        1.5],
        [:superior,    2.0],
        [:masterwork,  5.0],
        [:legendary,   10.0],
    ]; end
    def self.standard; :standard; end
    extend DataTables
end

module Chance
    def self.raw_values; [
        [:unhead_of,  0.00001],
        [:rare,       0.001],
        [:unusual,    0.022],
        [:uncommon,   0.158],
        [:coin_toss,  0.5],
        [:likely,     0.842],
        [:probable,   0.978],
        [:certain,    0.999],
        [:guaranteed, 0.99999]
    ]; end
    def self.standard; :coin_toss; end
    extend DataTables

    def self.take(level); return (Kernel.rand < value_of(level)); end
end

module Rarity
    def self.raw_values; [
        [:extinct,    0.0],
        [:singular,   0.0001],
        [:rare,       0.1],
        [:unusual,    0.3],
        [:uncommon,   1.0],
        [:common,     2.5],
        [:thriving,   5.0],
        [:teeming,    10.0],
        [:ubiquitous, 100.0]
    ]; end
    def self.standard; :common; end
    extend DataTables
end

module Size
    def self.raw_values; [
        [:miniscule,  0.1],
        [:tiny,       0.25],
        [:small,      0.5],
        [:medium,     1.0],
        [:large,      2.0],
        [:enormous,   5.0],
        [:gargantuan, 10.0]
    ]; end
    def self.standard; :medium; end
    extend DataTables
end

DataTables.setup
