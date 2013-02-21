require './util/log'

module CFGReader
    class << self
        CFG_ROOT = "."

        def read(config_type)
            config = {}
            cfg_data = read_lines(config_type)
            return config unless cfg_data
            cfg_data.each do |line|
                key, value = parse_line(line)
                config[key] = value
            end
            config
        end

        def get_param(config_type, config_param)
            cfg_hash = read(config_type)
            cfg_hash[config_param]
        end

        private
        def read_lines(config_type)
            cfg_file = File.join(CFG_ROOT, config_type + ".cfg")
            unless File.exist?(cfg_file)
                Log.warning("Config file #{cfg_file} not found")
                nil 
            else
                File.readlines(cfg_file)
            end
        end

        def parse_line(line)
            inflection = line.index(/\s/)
            k = line[0...inflection].strip
            v = line[inflection..-1].strip
            if v[0,1] == "\"" && v[-1,1] == "\""
                v = v[1...-1]
            else
                v = v.to_i
            end
            [k.to_sym, v]
        end
    end
end
