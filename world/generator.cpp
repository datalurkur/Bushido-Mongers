#include "world/generator.h"
#include "util/pointquadtree.h"
#include "util/timer.h"
#include "util/geom.h"
#include "util/noise.h"

#include <vector>
#include <set>
#include <sstream>
#include <math.h>

World* WorldGenerator::GenerateWorld(int size, float sparseness, float connectedness, ConnectionMethod connectionMethod) {
  // Determine the number of features the world should contain
  int numFeatures = size - (int)((size - 1) * sparseness);
  int averageFeatureSize = max(1, (int)(size * sparseness / 2));
  int midSize = size / 2;
  float midSizeSquared = midSize * midSize;

  float maxConnectionDistance = averageFeatureSize * connectedness; 
  float maxConnDistSquared = maxConnectionDistance * maxConnectionDistance;

  Debug("Generating " << numFeatures << " features in a " << size << "-sized world");
  Debug("Average feature size " << averageFeatureSize << " and maximum connected feature distance " << maxConnectionDistance);

  // Generate a random point cloud
  vector<Feature* > features(numFeatures);

  int i;
  for(i = 0; i < numFeatures; i++) {
    int x = rand() % size,
        y = rand() % size,
        r = rand() % averageFeatureSize + (averageFeatureSize / 2);
    //Debug("Created a feature at (" << x << "," << y << ") with approximate size " << r);
    features[i] = new Feature(x, y, r);
  }

  // Do a *really* dumb and inefficient delaunay triangulation of the points
  set<pair<Feature*, Feature*> > connections;
  int triangleCount = 0,
      permutationCount = 0;
  int j, k;
  Timer t;
  t.start();
  for(i = 0; i < numFeatures - 2; i++) {
    for(j = i+1; j < numFeatures - 1; j++) {
      for(k = j+1; k < numFeatures; k++) {
        permutationCount++;
        Vec2 p;
        if(!computeCircleFromPoints(features[i]->getPos(), features[j]->getPos(), features[k]->getPos(), p)) {
          continue;
        }

        Vec2 r = features[i]->getPos() - p;
        float rSquared = r.magnitudeSquared();

        bool isDelaunay = true;
        // Determine if any other points lie within this circle
        for(int m = 0; m < numFeatures; m++) {
          if(m == i || m == j || m == k) { continue; }
          Vec2 d = features[m]->getPos() - p;
          float mRSquared = d.magnitudeSquared();
          if(mRSquared < rSquared) {
            // Point lies within the circle, this triangle is non-delaunay
            isDelaunay = false;
            break;
          }
        }
        if(isDelaunay) {
          // This triangle is delaunay, add its edges
          //Debug("Triangle found to be delaunay");
          // Do some sorting here to cut out redundant edges
          if(i < j) { 
            connections.insert(make_pair(features[i], features[j]));
          } else {
            connections.insert(make_pair(features[j], features[i]));
          }
          if(i < k) {
            connections.insert(make_pair(features[i], features[k]));
          } else {
            connections.insert(make_pair(features[k], features[i]));
          }
          if(j < k) {
            connections.insert(make_pair(features[j], features[k]));
          } else {
            connections.insert(make_pair(features[k], features[j]));
          }
          triangleCount++;
        }
      }
    }
  }
  Debug("Found " << triangleCount << " valid Delaunay triangles based on " << permutationCount << " possible triangles");
  t.stop();
  t.report();

  // Now that we have the features and their connectivity, create the areas and populate the world with them
  World* world = new World();
  int counter = 0;
  for(auto feature : features) {
    #pragma message "Give areas real names"
    ostringstream stream;
    stream << feature->getPos().x << "," << feature->getPos().y;
    counter++;
    string name = stream.str();

    Area* area = new Area(name, feature->getPos(), Vec2(feature->getRadius(), feature->getRadius()));
    world->addArea(area);
    feature->setArea(area);
  }

  // Add the connections to the world
  for(auto connection : connections) {
    bool valid = true;
    switch(connectionMethod) {
    case MaxDistance: {
      Vec2 d = connection.first->getPos() - connection.second->getPos();
      if(d.magnitudeSquared() >= maxConnDistSquared) { valid = false; }
    } break;
    case Centralization: {
      Vec2 d = connection.first->getPos() - connection.second->getPos();
      float distanceRatio = (midSizeSquared - (d.magnitudeSquared() / 2)) / midSizeSquared;
      if((float)rand() / RAND_MAX > (connectedness + distanceRatio) / 2) { valid = false; }
    }
    case Random:
      if((float)rand() / RAND_MAX > connectedness) { valid = false; }
      break;
    }
    if(valid) {
      world->addConnection(connection.first->getArea(), connection.second->getArea());
    }
  }

  return world;
}

void WorldGenerator::PlaceAreaTransitions(Area* area) {
  for(Area* connection : area->getConnections()) {
    // Determine the unit vector that points in the direction of the connected area
    
  }
}

void WorldGenerator::GenerateCave(Area* area, float openness, float density) {
  Perlin p(256);
  Vec2 scalar = area->getSize() / (32 * density);
  double cutoff = 0.5 - openness;
  Vec2 center = area->getSize() / 2.0f;
  double maxRadiusSquared = center.magnitudeSquared();
  const Vec2& areaSize = area->getSize();

  for(int i = 0; i < areaSize.x; i++) {
    for(int j = 0; j < areaSize.y; j++) {
      Vec2 coords(i, j);
      Vec2 nCoords = coords / scalar;
      Vec2 offset = coords - center;
      float adjust = offset.magnitudeSquared() / maxRadiusSquared;
      double pValue = p.noise3(nCoords.x, nCoords.y, 0.5) - adjust;
      if(pValue > cutoff) {
        area->getTile(coords).setType(Tile::Type::Ground);
      }
    }
  }
}

void WorldGenerator::GenerateHallways(Area* area, float density) {
}
