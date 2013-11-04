# TODO - add multiple names for certain values.

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

    def random
        raw_values.rand.first
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
        raise(ArgumentError, "No item #{item.inspect} found in #{self.inspect}.") unless @values.has_key?(item)
        @values[item]
    end

    def value_below(value)
        less_than = @values.select { |k, v| v <= value }
        raise(ArgumentError, "No value less than #{value} found in #{self.inspect}.") if less_than.empty?
        less_than.min_by { |k, v| value - v }.first
    end

    def value_at(index)
        raise(ArgumentError, "Index out of range.") if index < 0 || index >= @num_values
        raw_values[index].first
    end

    def index_of(item)
        raise(ArgumentError, "No item #{item} found in #{self.inspect}.") unless @indices.has_key?(item)
        @indices[item]
    end

    # Take the difference between relative_value and reference and apply it to value
    def adjust(value, relative_value, reference=nil)
        reference  ||= standard
        offset       = difference(reference, relative_value)
        normal_index = index_of(value)

        new_level = [[normal_index + offset, 0].max, @num_values-1].min
        value_at(new_level)
    end

    def difference(base_value, relative_value)
        index_of(relative_value) - index_of(base_value)
    end

    def clamp_index(index)
        [[index, 0].max, @num_values-1].min
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
        [:effortless,  0.0],
        [:trivial,     0.05],
        [:pedestrian,  0.1],
        [:easy,        0.2],
        [:simple,      0.3],
        [:normal,      0.4],
        [:challenging, 0.5],
        [:difficult,   0.6],
        [:demanding,   0.7],
        [:formidable,  0.8],
        [:dicey,       0.9],
        [:impossible,  1.0]
    ]; end
    def self.standard; :normal; end
    extend DataTables
end

module Quality
    def self.raw_values; [
        [:broken,      0.0],
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
    # These numbers describe a Kernel.rand, and standard deviations from it.
    def self.raw_values; [
        [:unhead_of,  0.00001],
        [:rare,       0.001],
        [:unusual,    0.022],
        [:uncommon,   0.158],
        [:unlikely,   0.3],
        [:coin_toss,  0.5],
        [:common,     0.7],
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
        [:singular,   0.001],
        [:rare,       0.01],
        [:unusual,    0.1],
        [:uncommon,   0.2],
        [:common,     0.4],
        [:thriving,   0.8],
        [:teeming,    0.9],
        [:ubiquitous, 1.0]
    ]; end
    def self.standard; :common; end
    extend DataTables

    def self.roll(level); return (Kernel.rand < value_of(level)); end
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

module Hardness
    def self.raw_values; [
        [:insubstantial, 0.0],
        [:jelly,         0.01],
        [:flesh,         0.03],
        [:graphite,      0.1],
        [:keratin,       0.2],
        [:copper,        0.3],
        [:iron,          0.4],
        [:apatite,       0.5],
        [:titanium,      0.6],
        [:steel,         0.65],
        [:quartz,        0.7],
        [:topaz,         0.8],
        [:corundum,      0.9],
        [:diamond,       1.0]
    ]; end
    def self.standard; :graphite; end
    extend DataTables
end

module GenericAspect
    def self.raw_values; [
        [:nonexistent, 0.0],
        [:atrocious,   0.05],
        [:laughable,   0.1],
        [:terrible,    0.2],
        [:pathetic,    0.3],
        [:mediocre,    0.4],
        [:decent,      0.5],
        [:good,        0.6],
        [:excellent,   0.7],
        [:great,       0.8],
        [:superb,      0.9],
        [:stupendous,  0.95],
        [:peerless,    1.0]
    ]; end
    def self.standard; :decent; end
    extend DataTables
end

module GenericSkill
    def self.raw_values; [
        [:no,           0.0],
        [:laughable,    0.1],
        [:novice,       0.2], # initiate
        [:passable,     0.3],
        [:capable,      0.4], # apprentice
        [:competent,    0.5],
        [:proficient,   0.6], # journeyman
        [:professional, 0.7],
        [:expert,       0.8], # adept
        [:great,        0.9],
        [:master,       0.95], # master
        [:peerless,     1.0]
    ]; end
    def self.standard; :novice; end
    extend DataTables
end

DataTables.setup
