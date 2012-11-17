class Array; def rand() self[Kernel.rand(self.size)]; end; end

class Set; def rand() self.to_a.rand; end; end

class String
    # For now, just capitalize the beginning.
    def sentence
        self.gsub(/^(\w)/) { $1.upcase }
    end
end