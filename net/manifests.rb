# This file is the location of shared structures that allow the client / server to communicate complex information

class Manifest
    def self.required_args; []; end

    def initialize(args={})
        self.class.required_args.each do |arg|
            raise(MissingProperty, "Expected property #{arg} for #{self.class} manifest") unless args.has_key?(arg)
        end
        @args = Marshal.load(Marshal.dump(args))
    end

    def method_missing(method, *args, &block)
        if self.class.required_args.include?(method)
            return @args[method]
        else
            raise(MissingProperty, "Unknown property #{method} queried for #{self.class} manifest")
        end
    end
end

class SaveGameInfo < Manifest
    def self.required_args; [:name, :created_on, :saved_on]; end
end

class CharacterInfo < Manifest
    def self.required_args; [:name, :created_on, :saved_on]; end
end
