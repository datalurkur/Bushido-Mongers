require 'rubygems'
require 'graphviz'

require 'raws/bushido_object'
require 'raws/db'

Log.setup("Main", "grapher")

group = "default"
grapher = GraphViz.new(:G, :type => :digraph, :ranksep => 1, :concentrate => true)
begin
    ObjectRawParser.load_db(group, grapher)
rescue Exception => e
    Log.warning(["Failed to finish parsing objects", e.message, e.backtrace])
end
grapher.output(:png => "#{group}_graph.png")
