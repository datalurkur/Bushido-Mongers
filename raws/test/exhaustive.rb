require './raws/db'
require './test/fake'

Log.setup("Main", "test")

$core = FakeCore.new
$core.db.each_type(true) do |type|
    args = {}
    required = $core.db.raw_info_for(type)[:needs]
    required.each do |req|
        value = case req
        when :relative_size; :medium
        when :name; "Test Name"
        else
            raise(NotImplementedError, "Can't handle required argument #{req.inspect}")
        end

        args[req] = value
    end
    if $core.db.is_type?(type, :made)
        args[:randomize] = true
    end
    Log.debug(["Creating a #{type.inspect}"])
    $core.create(type, args)
end
