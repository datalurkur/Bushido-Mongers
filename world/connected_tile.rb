class ConnectedTile
    def initialize
        @connections = {}
        clear_connections
    end

    def clear_connections
        @connections[:north] = nil
        @connections[:south] = nil
        @connections[:east]  = nil
        @connections[:west]  = nil
    end

    def north; @connections[:north]; end
    def south; @connections[:south]; end
    def east;  @connections[:east];  end
    def west;  @connections[:west];  end

    def set_connection(dir, tile)
        @connections[dir] = tile
    end
end
