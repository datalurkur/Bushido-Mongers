require 'zlib'

class String
    def deflate
=begin
        z = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION)
        deflated_data = z.deflate(self, Zlib::FINISH)
        z.close
        deflated_data
=end
        Zlib::Deflate.deflate(self)
    end
end
