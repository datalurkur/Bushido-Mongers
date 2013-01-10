require 'util/log'

def trap_signals(signals=["TERM","INT"], &block)
    signals.each do |signal|
        Signal.trap(signal) do
            Log.debug("Caught signal #{signal}", 5)
            block.call(signal)
        end
    end
end
