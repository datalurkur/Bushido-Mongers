require 'util/log'

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

Each raw file consists of a list of serialzed object statements.

OBJECT STATEMENTS
=================
Format: [abstract] <parent type> <type>

An "abstract" object is an object not to be instantiated, but to provide a means of categorizing a group of common objects and specifying properties and default values for those objects.

An object inherits all the properties, necessary parameters, creation procs, and default values of its parent object (note that this is recursive).

"root" is a reserved object.  Any object with "root" as its parent object is considered not to have a parent object.

OBJECT DESCRIPTIONS
===================
Format: <keyword> [keyword-specific parameters]

OBJECT DESCRIPTION KEYWORDS
===========================
"has", "has_many"
    Indicates that the object being described "has" the property indicated.
    "has_many" indicates that this property can contain multiple values.
Format: "has" / "has_many" <property type> <property name>
Description: None

"needs"
    Indicates that, in order to be instantiated, this object must be given the arguments listed.
Format: "needs" <argument list, whitespace-delimited>
Description: None

"at_creation"
    Provides a block of Ruby code to be evaluated during object instantiation.
    The block is assumed to receive a hash of object parameters and return a hash of property modifications.
Format: "at_creation"
Description: A block of raw Ruby code to be evaluated.

Any other keyword
    Any other keyword is assumed to be a default property value, and will be treated as such.
    The property must have been specified within the object, and the value provided will be parsed according to the type of said property.
Format: <property> <value>
Description: None

=end

module ObjectRawParser
    class << self
        RAWS_LOCATION = "raws"

        def load_objects(group)
            object_database = {}

            metadata = collect_raws_metadata(group)

            unparsed_objects = metadata.keys
            next_object = nil
            while (next_object = unparsed_objects.shift)
                parse_object(next_object, unparsed_objects, metadata, object_database)
            end
            object_database
        end

        def raws_list(group)
            group_dir = File.join(RAWS_LOCATION, group)
            unless File.exists?(group_dir)
                raise "No object group #{group} exists"
            end
            Dir.entries(group_dir).select { |file| file.match(/\.raw$/) }.collect do |file|
                File.join(group_dir, file)
            end
        end

        def collect_raws_metadata(group)
            typed_objects_hash = {}
            raws_list(group).each do |raw_file|
                raw_data = File.read(raw_file)
                raw_chunks = separate_lexical_chunks(raw_data)
                raw_chunks.each do |statement, data|
                    statement_pieces = statement.split(/\s+/)
                    if statement_pieces[0] == "abstract"
                        parent, type = statement_pieces[1..2]
                        abstract = true
                    else
                        parent, type = statement_pieces[0..1]
                        abstract = false
                    end
                    if typed_objects_hash.has_key?(type)
                        Log.debug(["Ignoring duplicate type #{type}", statement, data])
                        next
                    end
                    typed_objects_hash[type.to_sym] = {
                        :abstract => abstract,
                        :is_a     => parent.to_sym,
                        :data     => data,
                    }
                end
            end
            typed_objects_hash
        end

        def parse_object(next_object, unparsed_objects, metadata, object_database)
            Log.debug("Parsing object #{next_object.inspect}", 8)

            # Do some sanity checking
            unless metadata.has_key?(next_object)
                raise "Object metadata not found for #{next_object.inspect}"
            end
            if object_database.has_key?(next_object)
                raise "Database information already exists for #{next_object}"
            end

            object_metadata = metadata[next_object]

            # Ensure parents have already been parsed all the way up to the root object
            unless object_database.has_key?(object_metadata[:is_a]) || object_metadata[:is_a] == :root
                unparsed_objects.delete(object_metadata[:is_a])
                parse_object(object_metadata[:is_a], unparsed_objects, metadata, object_database)
            end

            # Begin accumulating object data for the database
            object_data = {
                :abstract       => object_metadata[:abstract],
                :is_a           => object_metadata[:is_a],
                :has            => {},
                :needs          => [],
                :at_creation    => [],
                :default_values => {}
            }

            # Set up to accumulate subtypes if this is an abstract type
            if object_data[:abstract]
                object_data[:subtypes] = []
            end

            # Pull in information from the parent(s)
            # Since this happens for every object (including abstract objects) we only need to do it for one level of parents
            unless object_data[:is_a] == :root
                parent_object = object_database[object_data[:is_a]]
                [:has, :needs, :at_creation, :default_values].each do |key|
                    object_data[key] = parent_object[key].dup
                end
                parent_object[:subtypes] << next_object
            end

            if object_metadata[:data]
                # Chunk up the lexical pieces of this object definition and deal with them one-by-one
                separate_lexical_chunks(object_metadata[:data]).each do |statement, data|
                    statement_pieces = statement.split(/\s+/)
                    case statement_pieces[0]
                    when "has","has_many"
                        raise "Insufficient arguments in #{statement.inspect}" unless statement_pieces.size >= 2
                        field = statement_pieces[2].to_sym
                        object_data[:has][field] = {
                            :type => statement_pieces[1].to_sym
                        }
                        (object_data[:has][field][:multiple] = true) if (statement_pieces[0] == "has_many")
                    when "needs"
                        object_data[:needs].concat(statement_pieces[1..-1].collect { |piece| piece.to_sym })
                    when "at_creation"
                        object_data[:at_creation] << Proc.new { |params| eval(data) }
                    else
                        field = statement_pieces[0].to_sym
                        unless object_data[:has].has_key?(field)
                            raise "Property #{field.inspect} not found for object #{next_object.inspect}"
                        end
                        values = statement_pieces[1..-1].collect do |piece|
                            case object_data[:has][field][:type]
                            when :sym
                                piece.to_sym
                            when :int
                                piece.to_i
                            when :float
                                piece.to_f
                            else
                                raise "Unsupported property type #{object_data[:has][field][:type].inspect}"
                            end
                        end
                        if object_data[:has][field][:multiple]
                            object_data[:default_values][field] ||= []
                            object_data[:default_values][field].concat(values)
                        else
                            raise "Too many values supplied for field #{field.inspect} in #{next_object.inspect} - #{values.inspect}" if values.size > 1
                            object_data[:default_values][field] = values[0]
                        end
                    end
                end
            end

            Log.debug("Adding object #{next_object.inspect}", 8)
            object_database[next_object] = object_data
        end

        def separate_lexical_chunks(raw_data, end_char=";", open_char="{", close_char="}")
            chunks = []
            start  = 0
            while start < raw_data.size
                first_end  = raw_data[start..-1].index(end_char)
                first_open = raw_data[start..-1].index(open_char)

                if first_end.nil? && first_open.nil?
                    # Check to see if all that's left is whitespace and finish up
                    if raw_data[start..-1].match(/\S/)
                        raise "Syntax error in raw data: unterminated phrase - #{raw_data[start..-1].inspect}"
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
                            raise "Syntax error in raw data: unterminated phrase - #{raw_data[start..-1].inspect}"
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
    end
end
