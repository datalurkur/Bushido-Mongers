require './game/cores/default'

module GameCoreLoader
    def save_core(core, extra_info)
        uid      = get_core_uid(core, extra_info)
        savename = get_saved_name(uid)

        packed_core_data  = Marshal.dump(DefaultCore.pack(core))
        packed_extra_info = Marshal.dump(extra_info)

        save_datum(savename, [packed_extra_info, packed_core_data])
        uid
    end

    def load_core(uid)
        savename     = get_saved_name(uid)
        extra_info   = nil
        core         = nil
        packed_datum = File.read(File.join(SAVEDIR, savename))

        begin
            extra_info_size, = packed_datum.unpack("N")
            extra_info_dump  = packed_datum[4, extra_info_size]
            packed_datum     = packed_datum[4+extra_info_size..-1]
            extra_info       = Marshal.load(extra_info_dump)

            packed_core_size, = packed_datum.unpack("N")
            packed_core_dump  = packed_datum[4, packed_core_size]
            packed_core       = Marshal.load(packed_core_dump)
            core              = DefaultCore.unpack(packed_core)
        rescue Exception => e
            Log.error(["Failed to load core #{uid} - #{e.message}", e.backtrace])
        end

        return [core, extra_info]
    end

    def get_saved_cores_info
        info = {}
        get_saved_core_names.each do |name|
            f = File.open(File.join(SAVEDIR, name), "r")
            begin
                extra_info_size, = f.read(4).unpack("N")
                extra_info_dump  = f.read(extra_info_size)
                extra_info       = Marshal.load(extra_info_dump)
            rescue Exception => e
                Log.error(["Failed to extract extra info from #{name} - #{e.message}", e.backtrace])
            end
            f.close

            uid       = extract_uid_from_name(name)
            info[uid] = extra_info
        end
        info
    end

private
    SAVEDIR = "./saved"

    def prepare_save_dir
        Dir.mkdir(SAVEDIR) unless File.exists?(SAVEDIR)
    end

    def get_core_uid(core, extra_info)
        str  = Time.now.to_s
        str += core.tick_count.to_s
        extra_info.each do |k,v|
            str += k.to_s + ":" + v.to_s
        end
        str.hash
    end

    def extract_uid_from_name(name)
        name[5..-1].to_i
    end

    def get_saved_name(uid)
        "core_#{uid}"
    end

    def save_datum(filename, datum)
        packed_datum = ""
        datum.each do |data|
            packed_datum += [data.size].pack("N")
            packed_datum += data
        end

        prepare_save_dir

        f = File.open(File.join(SAVEDIR, filename), "w")
        f.write(packed_datum)
        f.close
    end

    def get_saved_core_names
        prepare_save_dir
        Dir.entries(SAVEDIR) - [".", ".."]
    end

end
