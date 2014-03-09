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
        float pX, pY;
        if(!computeCircleFromPoints(features[i]->getX(), features[i]->getY(),
                                    features[j]->getX(), features[j]->getY(),
                                    features[k]->getX(), features[k]->getY(),
                                    pX, pY)) {
          continue;
        }

        float rX = features[i]->getX() - pX,
              rY = features[i]->getY() - pY,
              rSquared = (rX*rX) + (rY*rY);

        bool isDelaunay = true;
        // Determine if any other points lie within this circle
        for(int m = 0; m < numFeatures; m++) {
          if(m == i || m == j || m == k) { continue; }
          float dM = features[m]->getX() - pX;
          float dY = features[m]->getY() - pY;
          float mRSquared = (dM * dM) + (dY * dY);
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
    stream << feature->getX() << "," << feature->getY();
    counter++;
    string name = stream.str();

    Area* area = new Area(name, feature->getX(), feature->getY(), feature->getRadius(), feature->getRadius());
    world->addArea(area);
    feature->setArea(area);
  }

  // Add the connections to the world
  for(auto connection : connections) {
    bool valid = true;
    switch(connectionMethod) {
    case MaxDistance: {
      int dX = connection.first->getX() - connection.second->getX(),
          dY = connection.first->getY() - connection.second->getY();
      if((dX * dX) + (dY * dY) >= maxConnDistSquared) { valid = false; }
    } break;
    case Centralization: {
      int dX = (connection.first->getX() + connection.second->getX()) / 2 - midSize,
          dY = (connection.first->getY() + connection.second->getY()) / 2 - midSize;
      float distanceFromCenterSquared = (dX * dX) + (dY * dY);
      float distanceRatio = (midSizeSquared - (distanceFromCenterSquared / 2)) / midSizeSquared;
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

void WorldGenerator::GenerateCave(Area* area, float openness, float density) {
  Perlin p(256);
  double xScalar = area->getXSize() / 32,
         yScalar = area->getYSize() / 32;
  double cutoff = 0;
  double centerX = (double)area->getXSize() / 2,
         centerY = (double)area->getXSize() / 2;
  double maxRadiusSquared = (centerX * centerX) + (centerY * centerY);
  for(int i = 0; i < area->getXSize(); i++) {
    for(int j = 0; j < area->getYSize(); j++) {
      double x = (double)i / xScalar;
      double y = (double)j / yScalar;
      double dI = i - centerX,
             dJ = j - centerY;
      double adjust = ((dI * dI) + (dJ * dJ)) / maxRadiusSquared;
      double pValue = p.noise3(x, y, 0.5) - adjust;
      if(pValue > cutoff) {
        area->getTile(i, j).setType(Tile::Type::Ground);
      }
    }
  }
}
