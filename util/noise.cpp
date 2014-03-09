#include "util/noise.h"
#include <stdlib.h>

Perlin::Perlin(int size): _size(size) {
  int i, j, temp;

  // Allocate memory for the permutation table
  _p = (int*)malloc(2 * _size * sizeof(int));

  // Setup the static list of permutations
  for(i = 0; i < _size; i++) {
    _p[i] = i;
  }
  
  // Randomly order the permutations
  for(i = (_size - 1); i > 0; i--) {
    j = rand() % (i + 1);
    temp = _p[i];
    _p[i] = _p[j];
    _p[j] = temp;
  }

  // Double the permutation table for overflows (we do this for speed, rather than checking for overflow and wrapping)
  for(i = 0; i < _size; i++) {
    _p[i + _size] = _p[i];
  }
}

Perlin::~Perlin() {
  free(_p);
}

double Perlin::noise2(double x, double y) {
  int fX, fY;
  double dX, dY;
  double u,v;
  int a, b;

  fX = ((int)x) % _size;
  fY = ((int)y) % _size;

  dX = x - (int)x;
  dY = y - (int)y;

  u = fade(dX);
  v = fade(dY);

  a = _p[fX]   + fY;
  b = _p[fX+1] + fY;

  return lerp(v,
    lerp(u,
      gradient2(_p[a],   dX,   dY  ),
      gradient2(_p[b],   dX-1, dY  )
    ),
    lerp(u,
      gradient2(_p[a+1], dX,   dY-1),
      gradient2(_p[b+1], dX-1, dY-1)
    )
  );
}
double Perlin::noise3(double x, double y, double z) {
  int fX, fY, fZ;
  double dX, dY, dZ;
  double u, v, w;
  int a, aa, ab, b, ba, bb;

  // Determine the bounds of the unit cube this point is inside
  fX = ((int)x) % _size;
  fY = ((int)y) % _size;
  fZ = ((int)z) % _size;

  // Determine the difference of this point from the origin of the unit cube
  dX = x - (int)x;
  dY = y - (int)y;
  dZ = z - (int)z;

  // Determine fade values for each dimension using our location inside the unit cube
  u = fade(dX);
  v = fade(dY);
  w = fade(dZ);

  // Find pseudo-random gradients by operating on the dimensional indices of the unit cube
  // The important part here is that these pseudo-random gradients are always the same for a given point
  a  = _p[fX]     + fY;
  aa = _p[a]      + fZ;
  ab = _p[a + 1]  + fZ;
  b  = _p[fX + 1] + fY;
  ba = _p[b]      + fZ;
  bb = _p[b+1]    + fZ;

  // Here we take the gradients at each of the 8 corners of the unit cube and linearly interpolate for each dimension (first x, then y, then z) using the fade values
  return lerp(w,
    lerp(v,
      lerp(u,
        gradient3(_p[aa],   dX,   dY,   dZ  ),
        gradient3(_p[ba],   dX-1, dY,   dZ  )
      ),
      lerp(u,
        gradient3(_p[ab],   dX,   dY-1, dZ  ),
        gradient3(_p[bb],   dX-1, dY-1, dZ  )
      )
    ),
    lerp(v,
      lerp(u,
        gradient3(_p[aa+1], dX,   dY,   dZ-1),
        gradient3(_p[ba+1], dX-1, dY,   dZ-1)
      ),
      lerp(u,
        gradient3(_p[ab+1], dX,   dY-1, dZ-1),
        gradient3(_p[bb+1], dX-1, dY-1, dZ-1)
      )
    )
  );
}

double Perlin::fade(double t) {
  return (t * t * t * ((t * ((t * 6) - 15)) + 10));
}

double Perlin::lerp(double t, double a, double b) {
  return (a + (t * (b - a)));
}

double Perlin::gradient2(int hash, double x, double y) {
  double r;

  r = (hash & 0x02) ? x : y;
  return ((hash & 0x01) ? r : -r);
}

/*
  Interestingly enough, this algorith mis slightly biased towards certain gradients in favor of speed
  Since we're choosing from 12 unique gradients, but since - thanks to prime factorization theorem - there's
    no squeezing 12 unique values out of a binary system without a modulus, we use something kinda hacky for speed
  If you look closely, you'll see that 4 of the gradients are overrepresented
    (the ones that result from the cases where h > 11)
*/
double Perlin::gradient3(int hash, double x, double y, double z) {
  int h;
  double u, v;

  h = hash & 0x0f;
  u = ((h<8) ? x : y);
  v = ((h<4) ? y : ((h==12 || h==14) ? x : z));
  return ((((h & 0x01) == 0) ? u : -u) + (((h & 0x02) == 0) ? v : -v));
}
