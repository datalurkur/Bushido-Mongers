require 'util/log'
require 'util/basic'

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
Format: [abstract] <parent type(s)> <type>

An "abstract" object is an object not to be instantiated, but to provide a means of categorizing a group of common objects and specifying properties and default values for those objects.

An object inherits all the properties, necessary parameters, creation procs, and default values of its parent object(s) (note that this is recursive). Multiple parent objects are delimited using commas (note that whitespace is not allowed within the comma-delimited list).

"root" is a reserved object.  Any object with "root" as its parent object is considered not to have a parent object.

OBJECT DESCRIPTIONS
===================
Format: <keyword> [keyword-specific parameters]

OBJECT DESCRIPTION KEYWORDS
===========================
"uses"
    Indicates that the object being described makes use of the module indicated.
    Certain methods in the module will be called upon during certain events (at_creation, at_message).
Format: "uses" <module name>
Description: None

"has", "has_many", "class", "class_many"
    Indicates that the object being described "has" the property indicated.
    "has_many" indicates that this property can contain multiple values.
    The "class" variants indicate that the property is class information only and is not to be propagated into instantiated objects.  Note that property names must still be unique across "has" and "class".
    The "optional" tag indicates that this property does not necessarily contain a value.
Format: "has" / "has_many" [optional] <property type> <property name>
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

        class DatabaseBinding
        end

        def load_objects(group)
            object_database = {}

            metadata, post_processes = collect_raws_metadata(group)

            unparsed_objects = metadata.keys
            next_object = nil
            while (next_object = unparsed_objects.shift)
                parse_object(next_object, unparsed_objects, metadata, object_database)
            end

            Log.debug("Performing #{post_processes.size} post-processing steps on database")
            db = ObjectDB.new(object_database)
            post_processes.each do |raw_code|
                eval(raw_code, db.get_binding, __FILE__, __LINE__)
            end
            db
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
            post_processes     = []
            raws_list(group).each do |raw_file|
                Log.debug("Parsing file #{raw_file}")
                raw_data = File.read(raw_file)
                raw_data.gsub!(/\/\*(.*?)\*\//, '')
                raw_chunks = separate_lexical_chunks(raw_data)
                raw_chunks.each do |statement, data|
                    statement_pieces = statement.split(/\s+/)
                    if statement_pieces[0] == "post_process"
                        post_processes << data
                    else
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
                            :is_a     => parent.split(/,/).collect { |p| p.to_sym },
                            :data     => data,
                        }
                    end
                end
            end
            [typed_objects_hash, post_processes]
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
            object_metadata[:is_a].each do |parent|
                unless object_database.has_key?(parent) || parent == :root
                    unparsed_objects.delete(parent)
                    parse_object(parent, unparsed_objects, metadata, object_database)
                end
            end

            # Begin accumulating object data for the database
            object_data = {
                :abstract     => object_metadata[:abstract],
                :is_a         => object_metadata[:is_a].dup,
                :uses         => [],
                :has          => {},
                :needs        => [],
                :at_creation  => [],
                :class_values => {}
            }

            # Set up to accumulate subtypes if this is an abstract type
            if object_data[:abstract]
                object_data[:subtypes] = []
            end

            # Pull in information from the parent(s)
            # Since this happens for every object (including abstract objects) we only need to do it for one level of parents
            # Do this backwards to respect parent ordering (most significant first)
            object_data[:is_a].reverse.each do |parent|
                #Log.debug("Merging properties of #{parent} into #{next_object}", 8)
                unless parent == :root
                    parent_object = object_database[parent]
                    raise "Parent object type '#{parent}' not abstract!" unless parent_object[:abstract]

                    [:uses, :has, :needs, :at_creation, :class_values].each do |key|
                        # Just dup isn't enough here, because occasionally we have an array within a hash that doesn't get duped properly
                        dup_data = Marshal.load(Marshal.dump(parent_object[key]))
                        #Log.debug(["Dup data is ", dup_data], 8)
                        case dup_data
                        when Array
                            object_data[key].concat(dup_data)
                        when Hash
                            object_data[key].merge!(dup_data)
                        else
                            raise "Parser doesn't know how to merge attributes of type #{dup_data.class}"
                        end
                    end

                    parent_object[:subtypes] << next_object
                end
            end

            if object_metadata[:data]
                # Chunk up the lexical pieces of this object definition and deal with them one-by-one
                separate_lexical_chunks(object_metadata[:data]).each do |statement, data|
                    statement_pieces = statement.split(/\s+/)
                    case statement_pieces[0]
                    when "uses"
                        Log.debug("#{next_object} uses #{statement_pieces[1..-1].inspect}",8)
                        raise "Insufficient arguments in #{statement.inspect}" unless statement_pieces.size >= 2
                        object_data[:uses].concat(statement_pieces[1..-1].collect { |m| m.to_caml.to_const })
                    when "has","has_many","class","class_many"
                        class_only, multiple = case statement_pieces[0]
                        when "has";        [false, false]
                        when "has_many";   [false, true]
                        when "class";      [true,  false]
                        when "class_many"; [true,  true]
                        end
                        optional = (statement_pieces[1] == "optional")
                        min_args = (optional ? 4 : 3)
                        unless statement_pieces.size >= min_args
                            raise "Insufficient arguments in #{statement.inspect}" 
                        end
                        type, field = if optional
                            statement_pieces[2..3]
                        else
                            statement_pieces[1..2]
                        end.collect(&:to_sym)
                        object_data[:has][field] = {
                            :class_only => class_only,
                            :type       => type
                        }
                        object_data[:has][field][:optional] = true if optional

                        if multiple
                            object_data[:has][field][:multiple] = true
                            object_data[:class_values][field] ||= []
                        end

                        #Log.debug(["Added property #{field}", object_data])
                    when "needs"
                        raise "Insufficient arguments in #{statement.inspect}" unless statement_pieces.size >= 2
                        object_data[:needs].concat(statement_pieces[1..-1].collect { |piece| piece.to_sym })
                    when "at_creation"
                        object_data[:at_creation] << data
                    else
                        field = statement_pieces[0].to_sym
                        unless object_data[:has].has_key?(field)
                            raise "Property #{field.inspect} not found for object #{next_object.inspect}"
                        end
                        values = statement_pieces[1..-1].collect do |piece|
                            case object_data[:has][field][:type]
                            when :string
                                piece
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
                            object_data[:class_values][field].concat(values)
                        else
                            Log.debug(["Ignoring extra values supplied for field #{field.inspect} in #{next_object.inspect}", values]) if values.size > 1
                            object_data[:class_values][field] = values[0]
                        end
                    end
                end
            end

            Log.debug(["Adding object #{next_object.inspect}", object_data], 6)
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
