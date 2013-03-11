require './raws/db'
require './test/fake'

Log.setup("Main", "test")

$db = ObjectDB.get("default")
$core = FakeCore.new($db)
$db.each_type(true) do |type|
    args = {}
    required = $db.raw_info_for(type)[:needs]
    required.each do |req|
        value = case req
        when :relative_size; :medium
        when :name; "Test Name"
        else
            raise(NotImplementedError, "Can't handle required argument #{req.inspect}")
        end

        args[req] = value
    end
    if $db.is_type?(type, :constructed)
        args[:randomize] = true
    end
    Log.debug(["Creating a #{type.inspect}"])
    $db.create($core, type, args)
end
