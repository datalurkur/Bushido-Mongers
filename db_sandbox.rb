require './test/fake'
require './raws/db'

Log.setup("Main", "db_sandbox")

core = CoreWrapper.new

while (str = gets)
    ret = eval str
    puts ret.inspect
end
