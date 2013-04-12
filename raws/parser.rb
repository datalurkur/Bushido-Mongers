require './util/log'
require './util/basic'
require './util/exceptions'

=begin

==============
| RAW FORMAT |
==============
Annotations:
<arg> - required argument arg
[arg] - optional argument arg

GENERAL RAW FORMAT
==================
Raws are formatted C-style, with whitespace being of no consequence.

Statements are terminated either with a semicolon or a description.

Descriptions are enclosed in curly braces and may contain any number of statements.

Comments are enclosed in /* */.

Each raw file consists of a list of serialzed object statements.

POST PROCESS STATEMENTS
=======================
Format: post_process

Defines a block of ruby code to be executed once the database has been completely populated.  The description is evaluated as-is.

OBJECT STATEMENTS
=================
Format: [abstract / extension_of] <parent type(s)> <type>

An "abstract" object is an object not to be instantiated, but to provide a means of categorizing a group of common objects and specifying properties and default values for those objects.

A "static" object is an object not to be instantiated, but not necessarily abstract.  This provides a mechanic for raw types like "command", which don't actually get created, to dictate what is actually a "command" and what is just a class of commands, which wouldn't normally be possible with just the abstract / non-abstract distinction.

An "extension_of" object is an object not to be instantiated, but to provide a means of adding certain properties to another object of the parent type.  Such an object can never be the parent of an object that does not also share its parent object.  Care should be taken when constructing extension objects, since they potentially present a diamond-problem scenario whose behavior is undefined. Extensions are implicitly abstract

An object inherits all the properties, necessary parameters, creation procs, and default values of its parent object(s) (note that this is recursive). Multiple parent objects are delimited using commas (note that whitespace is not allowed within the comma-delimited list).

OBJECT DESCRIPTIONS
===================
Format: <keyword> [keyword-specific parameters]

OBJECT DESCRIPTION KEYWORDS
===========================
"uses"
    Indicates that the object being described makes use of the module indicated.
    Certain methods in the module will be called upon during certain events (at_creation, at_message, at_destruction).
Format: "uses" <module name>
Description: None

"has", "has_many", "class", "class_many"
    Indicates that the object being described "has" the property indicated.
    "has_many" indicates that this property can contain multiple values.
    The "class" variants indicate that the property is class information only and is not to be propagated into instantiated objects.  Note that property names must still be unique across "has" and "class".
    The "optional" tag indicates that this property does not necessarily contain a value.
Format: "has" / "has_many" [optional] <property type> <property name>
Description: None (except for the "map" type, which has a list of property assignments)

"needs"
    Indicates that, in order to be instantiated, this object must be given the arguments listed.
Format: "needs" <argument list, whitespace-delimited>
Description: None

Any other keyword
    Any other keyword is assumed to be a default property value, and will be treated as such.
    The property must have been specified within the object, and the value provided will be parsed according to the type of said property.
Format: <property> <value>
Description: None

=end

module ObjectRawParser
    class << self
        def fetch(group)
            db = nil
            if File.exists?(preparsed_location(group))
                preparsed_data = File.read(preparsed_location(group))
                begin
                    Log.debug("Loading data from pre-parsed database")
                    preparsed_db = Marshal.load(preparsed_data)

                    if preparsed_db.hash == group_hash(group)
                        Log.debug("Using preparsed data")
                        db = preparsed_db
                    else
                        Log.debug("Rejecting preparsed data based on timestamp differences")
                    end
                rescue Exception => e
                    Log.debug(["Failed to load pre-parsed database", e.message, e.backtrace])
                end
            end

            if db.nil?
                Log.debug("Reloading objects")
                db = load_db(group)
                preparsed_handle = File.open(preparsed_location(group), "w")
                preparsed_handle.write(Marshal.dump(db))
                preparsed_handle.close
            end

            db
        end

        def load_db(group, grapher=nil)
            object_database = {}

            metadata, post_processes = collect_raws_metadata(group)

            if grapher
                graph_nodes = {}
                metadata.each do |i,data|
                    node_name    = i.to_s
                    node_options = {
                        :shape => "rect",
                        :style => "filled"
                    }
                    if data[:extension_of]
                        node_options[:color] = "orange"
                    elsif data[:is_type].empty?
                        node_options[:color] = "cyan"
                    elsif data[:static]
                        node_options[:color] = "purple"
                    elsif data[:abstract]
                        node_options[:color] = "white"
                    else
                        node_options[:color] = "green"
                    end
                    graph_nodes[i] = grapher.add_nodes(node_name, node_options)
                end
                metadata.each do |i,data|
                    data[:is_type].each do |parent_type|
                        grapher.add_edges(graph_nodes[i], graph_nodes[parent_type])
                    end
                    if data[:extension_of]
                        grapher.add_edges(graph_nodes[i], graph_nodes[data[:extension_of]], {
                            :style => "dashed",
                            :color => "orange"
                        })
                    end
                end
            end

            unparsed_objects = metadata.keys
            next_object = nil
            while (next_object = unparsed_objects.shift)
                parse_object(next_object, unparsed_objects, metadata, object_database)
            end

            Log.debug("Performing #{post_processes.size} post-processing steps on database")
            db = ObjectDB.new(object_database, group_hash(group))
            post_processes.each do |raw_code|
                begin
                    eval(raw_code, db.get_binding, __FILE__, __LINE__)
                rescue Exception => e
                    Log.error(["Failed to evaluate post-processing code", raw_code, e.message, e.backtrace])
                end
            end
            db
        end

        private
        RAWS_LOCATION = "raws"

        def group_hash(group)
            pertinent_files = [__FILE__].concat(raws_list(group))
            pertinent_files.collect { |file| File.mtime(file) }.hash
        end

        def preparsed_location(group)
            File.join(RAWS_LOCATION, group, ".preparsed")
        end

        def raws_list(group)
            group_dir  = File.join(RAWS_LOCATION, group)
            common_dir = File.join(RAWS_LOCATION, "common")
            get_raws_from_dir(group_dir) + get_raws_from_dir(common_dir)
        end

        def get_raws_from_dir(dir)
            unless File.exists?(dir)
                raise(ArgumentError, "No object directory #{dir} exists.")
            end
            Dir.glob(File.join(dir, "*")).select { |file| file.match(/\.raw$/) }
        end

        def collect_raws_metadata(group)
            typed_objects_hash = {}
            post_processes     = []
            raws_list(group).each do |raw_file|
                Log.debug("Parsing file #{raw_file}")
                raw_data = File.read(raw_file)
                raw_data.gsub!(/\/\*(.*?)\*\//m, '')
                separate_lexical_chunks(raw_data).each do |statement, data|
                    begin
                        chunks = statement.split(/\s+/).reject { |i| i.empty? }

                        case chunks[0]
                        when "post_process"
                            post_processes << data
                            next
                        when "abstract","static"
                            abstract     = true
                            static       = true if chunks[0] == "static"
                            if chunks.size > 2
                                parents      = chunks[1].split(/,/).collect(&:to_sym)
                                type         = chunks[2].to_sym
                            else
                                parents      = []
                                type         = chunks[1].to_sym
                            end
                        when "extension_of"
                            abstract     = true
                            parents      = []
                            extension_of = chunks[1].to_sym
                            type         = chunks[2].to_sym
                        else
                            if chunks.size > 1
                                parents      = chunks[0].split(/,/).collect(&:to_sym)
                                type         = chunks[1].to_sym
                            else
                                parents      = []
                                type         = chunks[0].to_sym
                            end
                        end

                        if typed_objects_hash.has_key?(type)
                            Log.warning(["Ignoring duplicate type #{type}", statement])
                            next
                        end

                        object_metadata = {
                            :is_type  => parents,
                            :data     => data,
                        }
                        object_metadata[:abstract]     = true         if abstract
                        object_metadata[:static]       = true         if static
                        object_metadata[:extension_of] = extension_of if extension_of

                        typed_objects_hash[type] = object_metadata
                    rescue Exception => e
                        Log.error(["Error while parsing object definition #{statement.inspect}", e.message, e.backtrace])
                        raise(ParserError, "Error while parsing object definition #{statement.inspect}")
                    end
                end
            end
            [typed_objects_hash, post_processes]
        end

        # FIXME - Eventually, we'll want to handle the exceptions in this method gracefully rather than crashing
        def parse_object(object_type, unparsed_objects, metadata, object_database)
            Log.debug("Parsing object #{object_type.inspect}", 8)

            # Do some sanity checking
            unless metadata.has_key?(object_type)
                raise(ParserError, "Object metadata not found for #{object_type.inspect}.")
            end
            if object_database.has_key?(object_type)
                raise(ParserError, "Database information already exists for #{object_type}.")
            end

            object_metadata = metadata[object_type]

            # Ensure parents have already been parsed all the way up
            object_metadata[:is_type].each do |parent|
                unless object_database.has_key?(parent)
                    unparsed_objects.delete(parent)
                    parse_object(parent, unparsed_objects, metadata, object_database)
                end
            end

            # If this object is an extension, make sure the object it extends has been loaded as well
            extension_of = object_metadata[:extension_of]
            if extension_of && !object_database.has_key?(extension_of)
                unparsed_objects.delete(extension_of)
                parse_object(extension_of, unparsed_objects, metadata, object_database)
            end

            # Check for duplicate parent classes
            running_list = object_metadata[:is_type].dup
            inheritance_list = []
            until running_list.empty?
                inheritance_list.concat(running_list)
                running_list.collect! do |parent|
                    object_database[parent][:is_type]
                end
                running_list.flatten!
            end
            if inheritance_list.size != inheritance_list.uniq.size
                duplicate_elements = inheritance_list.select do |parent|
                    inheritance_list.index(parent) != inheritance_list.rindex(parent)
                end.uniq
                raise(ParserError, "Object #{object_type} has duplicate parents (#{duplicate_elements.inspect}).")
            end

            # Begin accumulating object data for the database
            object_data = {
                :is_type        => object_metadata[:is_type].dup,
                :uses           => [],
                :has            => {},
                :needs          => [],
                :class_values   => {}
            }
            # Accumulate optional tags
            [:abstract, :extension_of, :static].each do |key|
                object_data[key] = object_metadata[key] if object_metadata[key]
            end

            # Set up to accumulate subtypes if this is an abstract type
            if object_data[:abstract] && !object_data[:static]
                object_data[:subtypes] = []
            end

            # Pull in information from the parent(s)
            # Since this happens for every object (including abstract objects) we only need to do it for one level of parents
            # Do this backwards to respect parent ordering (most significant first)
            object_data[:is_type].reverse.each do |parent|
                parent_object = object_database[parent]
                raise(ParserError, "Parent object type '#{parent}' not abstract!") unless parent_object[:abstract] && !parent_object[:static]

                [:uses, :has, :needs, :class_values].each do |key|
                    merge_complex(object_data[key], parent_object[key])
                end

                parent_object[:subtypes] << object_type
            end

            if object_metadata[:data]
                # Chunk up the lexical pieces of this object definition and deal with them one-by-one
                separate_lexical_chunks(object_metadata[:data]).each do |statement, data|
                    chunks          = statement.split(/\s+/)
                    expression_type = chunks.shift.to_sym

                    case expression_type
                    when :uses
                        Log.debug("#{object_type} uses #{chunks.inspect}", 8)
                        raise(ParserError, "Insufficient arguments in #{statement.inspect}.") if chunks.empty?

                        modules = chunks.collect do |m|
                            begin
                                m.to_caml.to_const
                            rescue Exception => e
                                Log.error(["Failure while loading object extension #{m.inspect}", e.message, e.backtrace])
                                raise(ParserError, "Failed to load object extension #{m.inspect}.")
                            end
                        end.compact

                        object_data[:uses].concat(modules)
                    when :has, :has_many, :class, :class_many
                        class_only, multiple = case expression_type
                        when :has;        [false, false]
                        when :has_many;   [false, true]
                        when :class;      [true,  false]
                        when :class_many; [true,  true]
                        end
                        if chunks.first == "optional"
                            optional = true
                            chunks.shift
                        end
                        property_type, property = chunks.shift(2).collect(&:to_sym)
                        raise(ParserError, "Insufficient arguments in #{statement.inspect}.") if property_type.nil? || property.nil?
                        object_data[:has][property] = {:type => property_type}

                        # Perform the optional key assignments this way so we don't pollute the has with keys that have nil values
                        object_data[:has][property][:optional]   = true if optional
                        object_data[:has][property][:class_only] = true if class_only
                        object_data[:has][property][:multiple]   = true if multiple

                        if optional && multiple
                            object_data[:class_values][property] ||= []
                        end

                        case property_type
                        when :map
                            # Parse the key / value definitions
                            object_data[:has][property][:keys] ||= {}
                            separate_lexical_chunks(data).each do |substatement, subdata|
                                pieces        = substatement.split(/\s+/).collect(&:to_sym)
                                many          = (pieces[0] == :many)
                                key_type, key = (many ? pieces[1,2] : pieces[0,2])
                                if key.nil? || key_type.nil?
                                    Log.warning("Skipping malformed map key definition #{substatement.inspect}")
                                    next
                                end
                                object_data[:has][property][:keys][key] = {
                                    :type => key_type,
                                    :many => many
                                }
                            end
                        end
                    when :needs
                        raise(ParserError, "Insufficient arguments in #{statement.inspect}.") if chunks.empty?
                        object_data[:needs].concat(chunks.collect { |chunk| chunk.to_sym })
                    else
                        property      = expression_type
                        property_info = object_data[:has][property]
                        if object_data[:extension_of]
                            Log.debug("#{object_type} is an extension of #{object_data[:extension_of]}", 6)
                            property_info ||= object_database[object_data[:extension_of]][:has][property]
                        end
                        if property_info.nil?
                            raise(ParserError, "Property #{property.inspect} not found for object #{object_type.inspect}.")
                        end
                        property_type = property_info[:type]

                        values = case property_type
                        when :proc
                            [data]
                        when :map
                            map_data = {}
                            property_info[:keys].each do |k,v|
                                map_data[k] = [] if v[:many]
                            end
                            separate_lexical_chunks(data).each do |substatement, subdata|
                                sub_chunks    = substatement.split(/\s+/)
                                key           = sub_chunks[0].to_sym
                                key_type      = property_info[:keys][key][:type]
                                values        = extract_property_values(key_type, sub_chunks[1..-1])
                                if property_info[:keys][key][:many]
                                    map_data[key].concat(values)
                                else
                                    map_data[key] = values[0]
                                end
                            end
                            [map_data]
                        else
                            extract_property_values(property_type, chunks)
                        end

                        if property_info[:multiple]
                            object_data[:class_values][property] ||= []
                            object_data[:class_values][property].concat(values)
                        else
                            Log.error(["Ignoring extra values supplied for property #{property.inspect} in #{object_type.inspect}", values]) if values.size > 1
                            object_data[:class_values][property] = values[0]
                        end
                    end
                end
            end

            # Check static objects for properties that don't make sense
            if object_data[:static]
                object_data[:has].each do |key,value|
                    unless value[:class_only]
                        raise(ParserError, "Instantiable information #{key.inspect} found in static object #{object_type.inspect}") unless value[:class_only]
                    end
                end
                [:needs, :uses].each do |key|
                    raise(ParserError, "Static object #{object_type.inspect} has no need of #{key.inspect} information") unless object_data[key].empty?
                end
            end

            Log.debug(["Adding object #{object_type.inspect}", object_data], 6)
            object_database[object_type] = object_data
        end

        def separate_lexical_chunks(raw_data, end_char=";", open_char="{", close_char="}")
            # Do a sanity check on brace matching
            num_opens  = raw_data.count(open_char) 
            num_closes = raw_data.count(close_char)
            if num_opens > num_closes
                raise(ParserError, "Mismatched #{open_char} in raw data")
            elsif num_closes > num_opens
                raise(ParserError, "Mismatched #{close_char} in raw data")
            end

            chunks = []
            start  = 0
            while start < raw_data.size
                first_end  = raw_data[start..-1].index(end_char)
                first_open = raw_data[start..-1].index(open_char)

                if first_end.nil? && first_open.nil?
                    # Check to see if all that's left is whitespace and finish up
                    if raw_data[start..-1].match(/\S/)
                        raise(ParserError, "Syntax error in raw data: unterminated phrase - #{raw_data[start..-1].inspect}.")
                    end
                    break
                elsif first_open && (first_end.nil? || (first_open < first_end))
                    statement = raw_data[start, first_open].strip
                    start += (first_open + 1)

                    scope_level = 1
                    scope_start = start
                    last_scope  = nil
                    while (scope_level > 0)
                        regex = "[#{open_char}#{close_char}]"
                        last_scope = raw_data[start..-1].index(/#{regex}/)
                        if last_scope.nil?
                            raise(ParserError, "Syntax error in raw data: unterminated phrase - #{raw_data[start..-1].inspect}.")
                        end

                        if raw_data[(start + last_scope), 1] == open_char
                            scope_level += 1
                        else
                            scope_level -= 1
                        end
                        start += (last_scope + 1)
                    end
                    data = raw_data[scope_start...(start-1)].strip
                    chunks << [statement, data]
                elsif first_end && (first_open.nil? || (first_end < first_open))
                    chunks << [raw_data[start, first_end].strip, nil]
                    start += (first_end + 1)
                end
            end
            chunks
        end

        def extract_property_values(property_type, chunks)
            chunks.collect do |raw_value|
                case property_type
                when :string
                    raw_value
                when :sym
                    raw_value.to_sym
                when :int
                    raw_value.to_i
                when :float
                    raw_value.to_f
                when :bool
                    (raw_value.to_sym == :true)
                else
                    raise(ParserError, "Unsupported property type #{property_type.inspect}.")
                end
            end
        end

        def merge_complex(dest, source)
            if dest.class != source.class
                Log.error("Can't merge differently typed objects #{dest[key].class} and #{source[key].class}")
                return dest
            end

            case dest
            when Hash
                source.keys.each do |key|
                    if dest.has_key?(key)
                        merge_complex(dest[key], source[key])
                    else
                        dest[key] = Marshal.load(Marshal.dump(source[key]))
                    end
                end
            when Array
                dest.concat(source)
                dest.uniq!
            else
                raise(NotImplementedError, "Can't merge params of type #{dest.class} (#{dest.inspect} / #{source.inspect}.")
            end
        end
    end
end
