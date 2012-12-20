require 'set'

class CodeCoverage
    class << self
        def setup(covered_directories=["."])
            @classes         = {}
            @covered_methods = Set.new
            @covered_directories = covered_directories
        end

        def is_file_covered?(filename)
            @covered_directories.each do |dir|
                if File.exists?(File.join(dir, filename))
                    return true
                end
            end
            return false
        end

        def results
            @classes
        end

        def method_covered?(name)
            @covered_methods.member?(name)
        end

        def register_method(name, name_alias, klass)
            methods_for_class(klass)[name] = 0
            @covered_methods.add(name)
            @covered_methods.add(name_alias)
        end

        def method_called(name, klass)
            methods_for_class(klass)[name] += 1
        end

        def methods_for_class(klass)
            @classes[klass] ||= {}
        end
    end
end

class Object
    class << self
        def method_added(name)
            return unless caller && caller[0]
            return unless CodeCoverage.is_file_covered?(caller[0].split(/:/).first)
            return if CodeCoverage.method_covered?(name)

            name_alias = "codecov_#{name}".to_sym
            CodeCoverage.register_method(name, name_alias, self)

            self.class_eval %{
                alias_method '#{name_alias}', '#{name}'

                def #{name}(*args, &block)
                    CodeCoverage.method_called(:#{name}, #{self})
                    #{name_alias}(*args, &block)
                end
            }
        end
    end
end
