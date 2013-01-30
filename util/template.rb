require 'rubygems'
require 'haml'
require 'erb'

module TemplateRenderer
    def render_template(template_name, locals=nil)
        raise(ArgumentError, "Template #{template_name.inspect} does not exist.") unless File.exist?(template_name)
        template_ext  = template_name.split(/\./).last
        template_data = File.read(template_name)
        raise(StandardError, "Failed to load template data for #{template_name.inspect}.") unless template_data
        template_protect(template_ext, template_data, locals)
    end

    # Runs an ERB template evaluation in its own thread to protect the caller
    def template_protect(type, template_data, locals)
        return_value = nil

        sandbox = Thread.new(return_value) do |return_value|
            begin
                return_value = case type
                when "erb";  render_erb(template_data, locals)
                when "haml"; render_haml(template_data, locals)
                else;        raise(ArgumentError, "Unrecognized template type #{type.inspect}.")
                end
            rescue Exception => e
                Log.warning(["Caught exception from template rendering", e.message, e.backtrace])
            end
        end

        # Wait for the erb thread to finish with a 5-second timeout
        status = sandbox.join(5)
        sandbox.kill unless status

        return_value
    end

    def render_erb(data, bindings)
        erb = ERB.new(data)
        bindings ? erb.result(bindings) : erb.result
    end

    def render_haml(data, locals)
        haml = Haml::Engine.new(data)
        haml.render(Object.new, locals || {})
    end
end
