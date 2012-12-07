require 'game/descriptions'

Log.setup("Main Thread", "item_test")

Log.debug(["Headgear list:", Headgear.types])
Log.debug(["Metal list:", Metal.types])
Log.debug(["Items list:", Item.types])

iron = Iron.new
helmet = Helmet.new(:materials => [iron], :quality => :fine)
