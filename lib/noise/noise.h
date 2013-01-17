#ifndef NOISE_H
#define NOISE _H

#include "ruby.h"
#include "perlin.h"

extern void MarkPerlin(Perlin *cPerlin);
extern void FreePerlin(Perlin *cPerlin);
extern VALUE AllocPerlin(VALUE rPerlinClass);

extern void Init_noise();

extern VALUE Perlin3(VALUE rSelf, VALUE x, VALUE y, VALUE z);
extern VALUE Perlin2(VALUE rSelf, VALUE x, VALUE y);
extern VALUE NoiseSize(VALUE rSelf);

#endif
