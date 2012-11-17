require 'world/zone'
require 'basic_extensions'

# FIXME: Restructure ZoneTemplate as a factory.
# FIXME: Add keyword storing.

class ZoneTemplate
    class << self
        def register_template(template_class)
            @templates ||= []
            @templates << template_class
        end

        def define(zone, args = {})
            args[:depth_range] = 1..2 unless args[:depth_range]
            args[:depth_range] = (args[:depth_range]..args[:depth_range]) if Numeric === args[:depth_range]

            class_eval %{
                class #{zone.to_s.sentence}
                    DEPTH_RANGE = #{args[:depth_range]}
                    
                    def initialize
                        puts "Creating a new \#\{self.class\}."
                    end
                end
                self.register_template(#{zone.to_s.sentence})
            }
        end

        def rand(depth = :any)
            return @templates.rand if depth == :any
            return @templates.select { |t| t::DEPTH_RANGE.include?(depth) }.rand
        end
    end
end

if $0 == __FILE__
    ZoneTemplate.define(:castle, :depth_range => 1..2,
                        :keywords => [:constructed],
                        :optional_keywords => [:dank, :inhabited])

    puts "There's a #{ZoneTemplate::Castle} class now."
    puts "Instantiating: #{ZoneTemplate::Castle.new}."

    ZoneTemplate.define("Mountain_Range", :depth_range => 3..5,
                        :keywords => [:mountainous])

    ZoneTemplate.define("OnABoat", :depth_range => 1..3,
                        :keywords => [:wet])

    puts "There's a #{ZoneTemplate::OnABoat} class now."
    puts "Instantiating: #{ZoneTemplate::OnABoat.new}."

    p ZoneTemplate.rand
    p ZoneTemplate.rand(2)
    p ZoneTemplate.rand(3)
    p ZoneTemplate.rand(5)
end