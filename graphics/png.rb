require 'zlib'

# This is a simple class designed to produce indexed-color PNGs with no bullshit attached (no filtering, no interlacing)
# ImageMagick is a horrible, horrible Frankenstein creature
class DerpyPNG
    class << self
        def crc(data)
            Zlib::crc32(data)
        end

        def make_chunk(type,data="")
            length      = [data.size].pack("N")
            blob        = type + data
            crc_of_blob = [crc(blob)].pack("N")
            length + blob + crc_of_blob
        end

        def png_start
            [137,80,78,71,13,10,26,10].pack("C*")
        end

        def make_ihdr(width,height)
            type = "IHDR"
            data = [
                width,
                height,
                8, # Bit Depth
                3, # Color Type         (Indexed)
                0, # Compression Method (Deflate)
                0, # Filter method      (Adaptive filtering with 5 basic filter types)
                0, # Interlace method   (No interlacing)
            ].pack("NNCCCCC")
            make_chunk(type,data)
        end

        def make_plte(colors)
            type = "PLTE"
            data = colors.collect { |color|
                color.pack("CCC")
            }.join
            make_chunk(type,data)
        end

        def make_idat(compressed_chunk)
            type = "IDAT"
            make_chunk(type,compressed_chunk)
        end

        def make_iend
            type = "IEND"
            make_chunk(type)
        end
    end

    attr_reader :width, :height, :colors
    def initialize(width,height)
        @colors = []
        @width  = width
        @height = height
        @bitmap = Array.new(width) { Array.new(height,0) }
    end

    def maximize_contrast
        min=[255,255,255]
        max=[0,0,0]
        @colors.each do |r,g,b|
            min[0] = [min[0],r].min
            min[1] = [min[1],g].min
            min[2] = [min[2],b].min
            max[0] = [max[0],r].max
            max[0] = [max[1],g].max
            max[0] = [max[2],b].max
        end
        range=(0...3).collect { |i| max[i] - min[i] }
        irange = range.collect do |r|
            begin
                1 / r
            rescue
                0
            end
        end
        @colors.collect! do |r,g,b|
            new_r = (255 * ((r - min[0]) * irange[0])).to_i
            new_g = (255 * ((g - min[1]) * irange[1])).to_i
            new_b = (255 * ((b - min[2]) * irange[2])).to_i
            [new_r,new_g,new_b]
        end
    end

    def set_pixel_at(x,y,index)
        @bitmap[y][x] = index
    end

    def set_pixel(x,y,r,g,b)
        color_index = @colors.index([r,g,b])
        unless color_index
            color_index = @colors.size
            @colors << [r,g,b]
        end
        set_pixel_at(x,y,color_index)
    end

    def interlace
        # Do nothing!  Hah!  Suck it interlacing!
        @bitmap.collect { |scanline| scanline.pack("C*") }
    end

    def filter(scanlines)
        # Do nothing again.  Look at all the craps I give.
        scanlines.collect do |scanline|
            [0].pack("C") + scanline
        end.join
    end

    def compress(stream)
        Zlib::Deflate.deflate(stream)
    end

    def save(filename)
        interlaced_data = interlace
        filtered_data = filter(interlaced_data)
        compressed_data = compress(filtered_data)

        file_data = [
            DerpyPNG.png_start(),
            DerpyPNG.make_ihdr(width,height),
            DerpyPNG.make_plte(colors),
            DerpyPNG.make_idat(compressed_data),
            DerpyPNG.make_iend()
        ].join

        f = File.open(filename, "w")
        f.write(file_data)
        f.close
    end
end
