#ifndef VECTOR_H
#define VECTOR_H

#include <math.h>
#include <sstream>

using namespace std;

template <typename T>
class VectorBase {
public:
  T x, y;

  VectorBase();
  VectorBase(const VectorBase<T>& other);

  template <typename S>
  VectorBase(const VectorBase<S>& other);

  VectorBase(T nx, T ny);

  void normalize();
  void clampLower(T l);
  void clampUpper(T u);
  T magnitude();
  T magnitudeSquared() const;

  template <typename S>
  operator VectorBase<S>();

  VectorBase<T>& operator=(const VectorBase<T>& other);
  VectorBase<T>& operator+=(const VectorBase<T>& other);

  bool operator<(const VectorBase<T>& other) const;
  bool operator==(const VectorBase<T>& rhs) const;
  bool operator!=(const VectorBase<T>& rhs) const;

protected:
  bool _magnitudeCached;
  T _cachedMagnitude;
};

typedef VectorBase<int> IVec2;
typedef VectorBase<float> Vec2;

template <typename T>
VectorBase<T>::VectorBase(): x(0), y(0), _magnitudeCached(false), _cachedMagnitude(0) {}

template <typename T>
VectorBase<T>::VectorBase(const VectorBase<T>& other): x(other.x), y(other.y), _magnitudeCached(false), _cachedMagnitude(0) {}

template <typename T>
template <typename S>
VectorBase<T>::VectorBase(const VectorBase<S>& other): x((T)other.x), y((T)other.y), _magnitudeCached(false), _cachedMagnitude(false) {}

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
T VectorBase<T>::magnitude() {
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

template <typename T>
template <typename S>
VectorBase<T>::operator VectorBase<S>() { return VectorBase<S>(*this); }

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

// Logical operators
template <typename T>
bool VectorBase<T>::operator<(const VectorBase<T>& other) const {
  return (x < other.x || (x == other.x && (y < other.y)));
}
template <typename T>
bool VectorBase<T>::operator==(const VectorBase<T>& rhs) const {
  return (x == rhs.x && y == rhs.y);
}
template <typename T>
bool VectorBase<T>::operator!=(const VectorBase<T>& rhs) const {
  return (x != rhs.x || y != rhs.y);
}
template <typename T>
bool magnitudeLess(const T& lhs, const T& rhs) {
  return lhs.magnitudeSquared() < rhs.magnitudeSquared();
}
template <typename T>
bool magnitudeGreater(const T& lhs, const T& rhs) {
  return lhs.magnitudeSquared() > rhs.magnitudeSquared();
}

template <typename T>
ostream& operator<<(ostream& lhs, const VectorBase<T>& rhs) {
  lhs << "{" << rhs.x << "," << rhs.y << "}";
  return lhs;
}

template <typename T>
VectorBase<T>& VectorBase<T>::operator=(const VectorBase<T>& other) {
  x = other.x;
  y = other.y;
  _magnitudeCached = other._magnitudeCached;
  _cachedMagnitude = other._cachedMagnitude;
  return *this;
}

template <typename T>
VectorBase<T>& VectorBase<T>::operator+=(const VectorBase<T>& other) {
  x += other.x;
  y += other.y;
  _magnitudeCached = false;
  return *this;
}

#endif
