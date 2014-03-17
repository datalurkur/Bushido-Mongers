#ifndef VECTOR_H
#define VECTOR_H

#include <math.h>

template <typename T>
class VectorBase {
public:
  T x, y;

  VectorBase();
  VectorBase(const VectorBase<T>& other);
  VectorBase(T nx, T ny);

  void normalize();
  void clampLower(T l);
  void clampUpper(T u);
  T magnitude() const;
  T magnitudeSquared() const;

protected:
  bool _magnitudeCached;
  T _cachedMagnitude;
};

typedef VectorBase<int> IVec2;
typedef VectorBase<float> Vec2;

template <typename T>
VectorBase<T>::VectorBase(): x(0), y(0), _magnitudeCached(false), _cachedMagnitude(0) {}

template <typename T>
VectorBase<T>::VectorBase(const VectorBase<T>& other): x(other.x), y(other.y), _magnitudeCached(false), _cachedMagnitude(false) {}

template <typename T>
VectorBase<T>::VectorBase(T nx, T ny): x(nx), y(ny), _magnitudeCached(false), _cachedMagnitude(0) {}

template <typename T>
void VectorBase<T>::normalize() {
  T m = magnitude();
  x /= m;
  y /= m;
  _cachedMagnitude = 1;
  _magnitudeCached = true;
}

template <typename T>
void VectorBase<T>::clampLower(T l) {
  x = max(x, l);
  y = max(y, l);
}

template <typename T>
void VectorBase<T>::clampUpper(T u) {
  x = min(x, u);
  y = min(y, u);
}

template <typename T>
T VectorBase<T>::magnitude() const {
  if(!_magnitudeCached) {
    _cachedMagnitude = sqrt(magnitudeSquared());
    _magnitudeCached = true;
  }
  return _cachedMagnitude;
}

template <typename T>
T VectorBase<T>::magnitudeSquared() const {
  return (x * x) + (y * y);
}

// Arithmetic operators
template <typename T>
VectorBase<T> operator+(const VectorBase<T>& lhs, const VectorBase<T>& rhs) {
  return VectorBase<T>(lhs.x + rhs.x, lhs.y + rhs.y);
}
template <typename T>
VectorBase<T> operator-(const VectorBase<T>& lhs, const VectorBase<T>& rhs) {
  return VectorBase<T>(lhs.x - rhs.x, lhs.y - rhs.y);
}
template <typename T>
VectorBase<T> operator*(const VectorBase<T>& lhs, const VectorBase<T>& rhs) {
  return VectorBase<T>(lhs.x * rhs.x, lhs.y * rhs.y);
}
template <typename T>
VectorBase<T> operator*(const VectorBase<T>& lhs, T rhs) {
  return VectorBase<T>(lhs.x * rhs, lhs.y * rhs);
}
template <typename T>
VectorBase<T> operator/(const VectorBase<T>& lhs, const VectorBase<T>& rhs) {
  return VectorBase<T>(lhs.x / rhs.x, lhs.y / rhs.y);
}
template <typename T>
VectorBase<T> operator/(const VectorBase<T>& lhs, T rhs) {
  return VectorBase<T>(lhs.x / rhs, lhs.y / rhs);
}
template <typename T>
bool operator<(const VectorBase<T>& lhs, const VectorBase<T>& rhs) {
  return (lhs.x < rhs.x || (lhs.x == rhs.x && (lhs.y < rhs.y)));
}

#endif
