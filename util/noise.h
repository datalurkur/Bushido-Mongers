#ifndef NOISE_H
#define NOISE_H

class Perlin {
public:
  Perlin(int size);
  ~Perlin();

  double noise2(double x, double y);
  double noise3(double x, double y, double z);

private:
  double fade(double t);
  double lerp(double t, double a, double b);
  double gradient2(int hash, double x, double y);
  double gradient3(int hash, double x, double y, double z);

private:
  int _size;
  int *_p;
};

#endif
