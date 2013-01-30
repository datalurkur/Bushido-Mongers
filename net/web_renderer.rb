require './util/template'

module WebRenderer
    include TemplateRenderer

    def wildcard
        "([^\/]*)"
    end

    def get_template(template_name, locals={})
        [render_template(template_name, locals), "text/html"]
    end

    def get_file(filename)
        begin
            unless File.exist?(filename)
                Log.debug("#{filename} does not exist", 7)
                return nil
            end
            if File.directory?(filename)
                Log.debug("#{filename} is a directory", 7)
                return nil
            end
            Log.debug("Loading #{filename}", 7)
            data           = File.read(filename)

            file_extension = filename.split(/\./).last
            type = case file_extension
            when "ico";        "image/x-icon"
            when "png";        "image/png"
            when "jpg","jpeg"; "image/jpeg"
            when "css";        "text/css"
            when "html";       "text/html"
            when "ttf";        "font/ttf"
            else
                Log.warning("Unrecognized extension #{file_extension}")
                "text/plain"
            end
            [data, type]
        rescue Exception => e
            Log.debug(["Failed to load data from #{filename}", e.message, e.backtrace])
            nil
        end
    end
end
