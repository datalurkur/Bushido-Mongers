require './util/log'

class Repro
    def self.load(file)
        Log.debug("Loading repro events from #{file}")
        f = File.read(file)

        seed, num_events = f.unpack("NN")
        f = f[8..-1]

        Log.debug("\tLoading #{num_events} events")
        events = []
        num_events.times do
            event, f = ReproEvent.unpack(f)
            events << event
        end

        return Repro.new(:seed => seed, :events => events)
    end

    attr_reader :seed, :events

    def initialize(args={})
        @events     = args[:events] || []
        @seed       = args[:seed]
        @start_time = args[:start_time]
    end

    def save_events(file)
        Log.info("Saving repro to #{file.inspect}")
        f = File.open(file, "w")
        f.write([@seed, @events.size].pack("NN"))
        @events.each do |event|
            f.write(event.pack)
        end
        f.close
    end

    def add_event(event, type=nil, extra=nil)
        Log.debug(["Adding repro event:", event], 8)
        @events << ReproEvent.new(:data => event, :type => type, :extra => extra, :offset => Time.now - @start_time)
    end
end

class ReproEvent
    TYPE_FLAG  = 0x80
    EXTRA_FLAG = 0x40

    def self.unpack(stream)
        offset, flags = stream.unpack("NC")
        stream = stream[5..-1]

        if (flags & TYPE_FLAG) != 0
            type_size = stream.unpack("N").first
            type_glob = stream[4, type_size]
            type = Marshal.load(type_glob)
            stream = stream[4+type_size..-1]
        end

        if (flags & EXTRA_FLAG) != 0
            extra_size = stream.unpack("N").first
            extra_glob = stream[4, extra_size]
            extra = Marshal.load(extra_glob)
            stream = stream[4+extra_size..-1]
        end

        data_size = stream.unpack("N").first
        data_glob = stream[4, data_size]
        data = Marshal.load(data_glob)
        stream = stream[4+data_size..-1]

        return [ReproEvent.new(:data => data, :type => type, :offset => offset, :extra => extra), stream]
    end

    attr_reader :offset, :type, :data, :extra

    def initialize(args={})
        @offset = args[:offset]
        @data   = args[:data]
        @type   = args[:type]
        @extra  = args[:extra]
    end

    def pack
        packed_data = [@offset].pack("N")

        flags  = 0
        flags |= TYPE_FLAG  if @type
        flags |= EXTRA_FLAG if @extra
        packed_data += [flags].pack("C")

        if @type
            marshaled_type = Marshal.dump(@type)
            packed_data += [marshaled_type.size].pack("N") + marshaled_type
        end

        if @extra
            marshaled_extra = Marshal.dump(@extra)
            packed_data += [marshaled_extra.size].pack("N") + marshaled_extra
        end

        marshaled_data = Marshal.dump(@data)
        packed_data += [marshaled_data.size].pack("N") + marshaled_data

        packed_data
    end
end
