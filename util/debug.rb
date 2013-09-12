class Debug
  def self.deep_search_types(object)
    types = []
    case object
    when Array
      types << Array
      object.each do |sub_obj|
        types.concat(deep_search_types(sub_obj))
      end
    when Hash
      types << Hash
      object.each_value do |sub_obj|
        types.concat(deep_search_types(sub_obj))
      end
    when Symbol,Fixnum,TrueClass,FalseClass,NilClass,Proc,String
      types << object.class
    when BushidoObject
      types << BushidoObject
    else
      raise "Unhandled type in deep search: #{object.class.inspect}"
    end

    return types.uniq
  end
end
