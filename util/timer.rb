require 'util/log'

module MeteredMethods
    class << self
        def data
            @data ||= {}
        end

        def setup?(method)
            data.has_key?(method)
        end

        def setup(method)
            data[method] = {
                :count => 0,
                :total => 0
            }
        end

        def add_datapoint(method, time)
            setup(method) unless setup?(method)
            data[method][:count] += 1
            data[method][:total] += time
        end

        def avg(method)
            data[method][:total] / data[method][:count]
        end

        def total(method)
            data[method][:total]
        end

        def report
            total_time = data.keys.sort { |a,b| total(a) <=> total(b) }.collect { |k| [k,total(k)] }
            Log.debug(["Total time spent in methods:", total_time])
            avg_time = data.keys.sort { |a,b| avg(a) <=> avg(b) }.collect { |k| [k,avg(k)] }
            Log.debug(["Average time spent in methods:", avg_time])
        end
    end
end

class Object
    class << self
        def metered(*method_names)
            method_names.each do |method|
                original = "old_#{method}".to_sym
                alias_method original, method
                class_eval %{
                    def #{method}(*args, &block)
                        start_timer = Time.now
                        ret = #{original}(*args, &block)
                        end_timer = Time.now
                        MeteredMethods.add_datapoint(#{method.inspect}, end_timer - start_timer)
                        ret
                    end
                }
            end
        end
    end
end
