#ifndef PERLIN_H
#define PERLIN_H

#include <stdlib.h>

typedef struct _Perlin {
    int size;
    int *p;
} Perlin;

extern double noise2(Perlin *perlin, double x, double y);
extern double noise3(Perlin *perlin, double x, double y, double z);
extern void setupPermutationTable(Perlin *perlin, int size);
extern void clearPermutationTable(Perlin *perlin);
extern double fade(double t);
extern double lerp(double t, double a, double b);
extern double gradient2(int hash, double x, double y);
extern double gradient3(int hash, double x, double y, double z);

extern double g3[];

#endif
