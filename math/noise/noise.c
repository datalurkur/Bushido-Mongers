#include "noise.h"

void MarkPerlin(Perlin *cPerlin) {
    // Do nothing
}

void FreePerlin(Perlin *cPerlin) {
    clearPermutationTable(cPerlin);
    free(cPerlin);
}

VALUE AllocPerlin(VALUE rPerlinClass) {
    Perlin *cPerlin = (Perlin*)malloc(sizeof(Perlin));
    setupPermutationTable(cPerlin, 256);
    VALUE rPerlin = Data_Wrap_Struct(rPerlinClass, MarkPerlin, FreePerlin, cPerlin);
    return rPerlin;
}

void Init_noise() {
    VALUE noiseClass = rb_define_class("Noise", rb_cObject);
    rb_define_method(noiseClass, "perlin3", RUBY_METHOD_FUNC(Perlin3), 3);
    rb_define_method(noiseClass, "perlin2", RUBY_METHOD_FUNC(Perlin2), 2);
    rb_define_alloc_func(noiseClass, AllocPerlin);
}

VALUE Perlin3(VALUE rSelf, VALUE x, VALUE y, VALUE z) {
    Perlin* cPerlin;
    double noise;

    Data_Get_Struct(rSelf, Perlin, cPerlin);
    return rb_float_new(noise3(cPerlin, NUM2DBL(x), NUM2DBL(y), NUM2DBL(z)));
}

VALUE Perlin2(VALUE rSelf, VALUE x, VALUE y) {
    Perlin* cPerlin;
    double noise;

    Data_Get_Struct(rSelf, Perlin, cPerlin);
    return rb_float_new(noise2(cPerlin, NUM2DBL(x), NUM2DBL(y)));
}
