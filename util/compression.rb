require 'zlib'
require 'stringio'

class String
    def deflate
        Zlib::Deflate.deflate(self)
    end

    def inflate
        Zlib::Inflate.inflate(self)
    end

    def gzip
        z = Zlib::GzipWriter.new(gzipped = StringIO.new)
        z.write(self)
        z.finish

        data = gzipped.string
        gzipped.close
        data
    end
end
