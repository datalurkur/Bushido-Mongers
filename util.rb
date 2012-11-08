class Object
    def defer_to(member, method)
        methods_to_defer = (Array === method) ? method : [method]
        methods_to_defer.each { |i|
            define_method(i) { |*args| instance_variable_get("@#{member}").send(i,*args) }
        }
    end
end
