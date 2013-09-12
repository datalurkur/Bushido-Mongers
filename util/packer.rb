module Packer
    def self.included(klass)
        klass.extend(InstancePacker)
    end

    def pack
        hash = {}
        self.class.packable.each do |key|
            hash[key] = self.instance_variable_get("@#{key}")
        end
        if self.respond_to?(:pack_custom)
            hash = self.pack_custom(hash)
        end
        hash
    end

    def unpack(*args)
        hash = args.last
        self.class.packable.each do |key|
            raise(MissingProperty, "#{self.class} data corrupt") unless hash.has_key?(key)
            self.instance_variable_set("@#{key}", hash[key])
        end
        if self.respond_to?(:unpack_custom)
            self.unpack_custom(*args)
        end
        self
    end
end

module InstancePacker
    def pack(instance); instance.pack;          end
    def unpack(*args);  self.new.unpack(*args); end
end
