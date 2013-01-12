#include "noise.h"

#define NOISE_SIZE 256

void MarkPerlin(Perlin *cPerlin) {
    // Do nothing
}

void FreePerlin(Perlin *cPerlin) {
    clearPermutationTable(cPerlin);
    free(cPerlin);
}

VALUE AllocPerlin(VALUE rPerlinClass) {
    VALUE rPerlin;
    Perlin *cPerlin;
    cPerlin = (Perlin*)malloc(sizeof(Perlin));
    setupPermutationTable(cPerlin, NOISE_SIZE);
    rPerlin = Data_Wrap_Struct(rPerlinClass, MarkPerlin, FreePerlin, cPerlin);
    return rPerlin;
}

void Init_noise() {
    VALUE noiseClass = rb_define_class("Noise", rb_cObject);
    rb_define_method(noiseClass, "perlin3", RUBY_METHOD_FUNC(Perlin3), 3);
    rb_define_method(noiseClass, "perlin2", RUBY_METHOD_FUNC(Perlin2), 2);
    rb_define_method(noiseClass, "noise_size", RUBY_METHOD_FUNC(NoiseSize), 0);
    rb_define_alloc_func(noiseClass, AllocPerlin);
}

VALUE Perlin3(VALUE rSelf, VALUE x, VALUE y, VALUE z) {
    Perlin* cPerlin;
    Data_Get_Struct(rSelf, Perlin, cPerlin);
    return rb_float_new(noise3(cPerlin, NUM2DBL(x), NUM2DBL(y), NUM2DBL(z)));
}

VALUE Perlin2(VALUE rSelf, VALUE x, VALUE y) {
    Perlin* cPerlin;
    Data_Get_Struct(rSelf, Perlin, cPerlin);
    return rb_float_new(noise2(cPerlin, NUM2DBL(x), NUM2DBL(y)));
}

VALUE NoiseSize(VALUE rSelf) {
    return INT2NUM(NOISE_SIZE);
}
