#ifndef GEOMETRY_H
#define GEOMETRY_H

#include "util/vector.h"

#include <set>
#include <list>

using namespace std;

extern bool computeCircleFromPoints(const Vec2& p0, const Vec2& p1, const Vec2& p2, Vec2& c);

extern void computeRasterizedCircle(int r, list<IVec2>& points);

extern void computeRasterizedDisc(int r, list<IVec2>& points);

extern void computeRasterizedLine(const IVec2& p0, const IVec2& p1, list<IVec2>& points);

#endif
