#include "util/geom.h"
#include <cmath>

using namespace std;

bool computeCircleFromPoints(float x0, float y0, float x1, float y1, float x2, float y2, float& pX, float& pY) {
  float dXA = x1 - x0,
        dYA = y1 - y0,
        dXB = x2 - x1,
        dYB = y2 - y1,
        mXA = (x0 + x1) / 2.0f,
        mYA = (y0 + y1) / 2.0f,
        mXB = (x1 + x2) / 2.0f,
        mYB = (y1 + y2) / 2.0f;

  // Check for degenerate cases
  if((dXA == 0 && dXB == 0) || (dYA == 0 && dYB == 0)) {
    return false;
  }

  if(dYA == 0) {
    pX = mXA;
    if(dXB == 0) {
      pY = mYB;
    } else {
      pY = mYB + ((mXB - pX) / (dYB / dXB));
    }
  } else if(dYB == 0) {
    pX = mXB;
    if(dXA == 0) {
      pY = mYA;
    } else {
      pY = mYA + ((mXA - pX) / (dYA / dXA));
    }
  } else if(dXA == 0) {
    pY = mYA;
    pX = ((dYB / dXB) * (mYB - pY)) + mXB;
  } else if(dXB == 0) {
    pY = mYB;
    pX = ((dYA / dXA) * (mYA - pY)) + mXA;
  } else {
    float sA = dYA / dXA,
          sB = dYB / dXB;
    pX = ((sA * sB * (mYA - mYB)) - (sA * mXB) + (sB * mXA)) / (sB - sA);
    pY = mYA - ((pX - mXA) / sA);
  }

  if(!isfinite(pX) || !isfinite(pY)) {
    return false;
  }

  return true;
}
