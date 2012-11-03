require 'interface'

class Client
    include DefaultInterface

    attr_reader :state
    def initialize(game)
        @fields  = {
            :player => "unnamed_player"
        }
        @state   = :invalid
        @game    = game
        clear_results
        clear_news
    end

    def set_state(state)
        debug("#{player}'s state set to #{state}",4)
        clear_results
        @state   = state
        case @state
        when :setup;   set_interface(setup_interface(@game))
        when :waiting; set_interface(waiting_interface)
        when :pending; set_interface(pending_interface)
        when :playing; set_interface(playing_interface(@game))
        else; raise "Unable to setup state for #{@state}"
        end
        consume_results
    end
    def process(input)
        (raise "Client improperly initialized") if (@state == :invalid)
        @interface.last.process(self,input)
        consume_results
    end

    def active?;  @state != :setup && @state != :defeated; end

    def add_news(news); @news << news; end
    def clear_news; @news = []; end
    def news; @news; end

    def player; field(:player); end

    def set_field(key, value); @fields[key] = value; end
    def field(key); @fields[key]; end

    # Result logging
    def append_result(result)
        case result
        when Array;  @results.concat(result)
        when String; @results << result
        end
    end
    def clear_results
        @results = []
    end
    def consume_results
        ret = @results.compact
        clear_results
        ret
    end

    # State maintenance
    def set_interface(iface)
        @interface = []
        push_interface(iface)
    end
    def push_interface(iface)
        @interface << iface
        if iface.prompt_when_current?
            debug("Prompting #{player}",4)
            append_result(iface.prompt(self)) 
        else
            debug("Not prompting #{player}",4)
        end
    end
    def pop_interface
        @interface.pop
        unless @interface.empty?
            if @interface.last.prompt_when_current?
                debug("Prompting #{player}",4)
                append_result(@interface.last.prompt(self)) 
            else
                debug("Not prompting #{player}",4)
            end
        end
    end
end
