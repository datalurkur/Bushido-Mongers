module Packer
    def self.included(klass)
        klass.extend(InstancePacker)
    end

    def pack
        hash = {}
        if self.respond_to?(:pack_custom)
            hash = self.pack_custom(hash)
        end
        self.class.packable.each do |key|
            if hash.has_key?(key)
                Log.warning("Possibly overwriting key #{key.inspect}")
            end
            hash[key] = self.instance_variable_get("@#{key}")
        end
        hash
    end

    def unpack(*args)
        if self.respond_to?(:unpack_custom)
            self.unpack_custom(*args)
        end
        hash = args.last
        self.class.packable.each do |key|
            raise(MissingProperty, "#{self.class} data corrupt") unless hash.has_key?(key)
            self.instance_variable_set("@#{key}", hash[key])
        end
        self
    end
end

module InstancePacker
    def pack(instance); instance.pack;          end
    def unpack(*args);  self.new.unpack(*args); end
end
