#include "util/geom.h"
#include <cmath>

using namespace std;

bool computeCircleFromPoints(const Vec2& p0, const Vec2& p1, const Vec2& p2, Vec2& c) {
  Vec2 dA = p1 - p0,
       dB = p2 - p1,
       mA = (p0 + p1) / 2.0f,
       mB = (p1 + p2) / 2.0f;

  // Check for degenerate cases
  if((dA.x == 0 && dB.x == 0) || (dA.y == 0 && dB.y == 0)) {
    return false;
  }

  if(dA.y == 0) {
    c.x = mA.x;
    if(dB.x == 0) {
      c.y = mB.y;
    } else {
      c.y = mB.y + ((mB.x - c.x) / (dB.y / dB.x));
    }
  } else if(dB.y == 0) {
    c.x = mB.x;
    if(dA.x == 0) {
      c.y = mA.y;
    } else {
      c.y = mA.y + ((mA.x - c.x) / (dA.y / dA.x));
    }
  } else if(dA.x == 0) {
    c.y = mA.y;
    c.x = ((dB.y / dB.x) * (mB.y - c.y)) + mB.x;
  } else if(dB.x == 0) {
    c.y = mB.y;
    c.x = ((dA.y / dA.x) * (mA.y - c.y)) + mA.x;
  } else {
    float sA = dA.y / dA.x,
          sB = dB.y / dB.x;
    c.x = ((sA * sB * (mA.y - mB.y)) - (sA * mB.x) + (sB * mA.x)) / (sB - sA);
    c.y = mA.y - ((c.x - mA.x) / sA);
  }

  if(!isfinite(c.x) || !isfinite(c.y)) {
    return false;
  }

  return true;
}
