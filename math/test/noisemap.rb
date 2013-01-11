require './math/noisemap'

size = 128
n = NoiseMap.new(size)
n.populate
n.save_to_png("noisemap_test.png")
