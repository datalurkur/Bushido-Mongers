#!/usr/bin/ruby
require 'rubygems'
require 'ruby-prof'

RubyProf.start

require './run_stack'

result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
