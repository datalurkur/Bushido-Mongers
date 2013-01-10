require 'zlib'

class String
    def deflate
        Zlib::Deflate.deflate(self)
    end

    def inflate
        Zlib::Inflate.inflate(self)
    end
end
