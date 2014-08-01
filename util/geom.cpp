#include "util/log.h"
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

void computeRasterizedCircle(int r, list<IVec2>& points) {
  int x = r,
      y = 0;

  int error = 1 - x;

  // Iterate over 1/8th of the circumference
  while(x >= y) {
    // Add 8 points for this iteration (one for each octant)
    points.push_back(IVec2( x,  y));
    points.push_back(IVec2( y,  x));
    points.push_back(IVec2(-x,  y));
    points.push_back(IVec2(-y,  x));
    points.push_back(IVec2(-x, -y));
    points.push_back(IVec2(-y, -x));
    points.push_back(IVec2( x, -y));
    points.push_back(IVec2( y, -x));

    y++;
    if(error < 0) {
      error += (2 * y) + 1;
    } else {
      x--;
      error += 2 * (y - x + 1);
    }
  }

  points.sort();
  points.unique();
}

void computeRasterizedDisc(int r, list<IVec2>& points) {
  int rSquared = r * r;
  for(int i = 0; i <= r; i++) {
    int xSquared = i * i;
    float yRange = sqrt((float)(rSquared - xSquared));
    points.push_back(IVec2( i, 0));
    if(i) {
      points.push_back(IVec2(-i, 0));
    }
    for(int j = 1; j <= yRange; j++) {
      points.push_back(IVec2( i,  j));
      points.push_back(IVec2( i, -j));
      if(i) {
        points.push_back(IVec2(-i,  j));
        points.push_back(IVec2(-i, -j));
      }
    }
  }
  computeRasterizedCircle(r, points);
}

void computeRasterizedLine(const IVec2& p0, const IVec2& p1, list<IVec2>& points) {
  int dx = abs(p1.x - p0.x),
      dy = abs(p1.y - p0.y),
      sx = (p0.x < p1.x) ? 1 : -1,
      sy = (p0.y < p1.y) ? 1 : -1,
      x = p0.x,
      y = p0.y,
      error = dx - dy;

  points.push_back(IVec2(x, y));
  while(x != p1.x || y != p1.y) {
    int e2 = error * 2;
    if(e2 > -dy) {
      error -= dy;
      x += sx;
    }
    if(e2 < dx) {
      error += dx;
      y += sy;
    }
    points.push_back(IVec2(x, y));
  }
}

IVec2 rotate(const IVec2& p, float rad) {
  float cV = cos(rad),
        sV = sin(rad);
  return IVec2(
    (p.x * cV) - (p.y * sV),
    (p.x * sV) + (p.y * cV)
  );
}
