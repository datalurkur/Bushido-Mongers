#include "world/generator.h"
#include "util/pointquadtree.h"
#include "util/timer.h"

#include <vector>
#include <set>
#include <sstream>
#include <math.h>

World* WorldGenerator::CloudGenerate(int size, float sparseness, float connectedness, ConnectionMethod connectionMethod) {
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
    int iX = features[i]->getX(),
        iY = features[i]->getY();

    for(j = i+1; j < numFeatures - 1; j++) {
      int jX = features[j]->getX(),
          jY = features[j]->getY();
      float dXA = jX - iX,
            dYA = jY - iY;

      for(k = j+1; k < numFeatures; k++) {
        permutationCount++;

        int kX = features[k]->getX(),
            kY = features[k]->getY();
        float dXB = kX - jX,
              dYB = kY - jY;
        float mXA = (iX + jX) / 2.0f,
              mYA = (iY + jY) / 2.0f,
              mXB = (jX + kX) / 2.0f,
              mYB = (jY + kY) / 2.0f;

        // Check for degenerate cases
        if((dXA == 0 && dXB == 0) || (dYA == 0 && dYB == 0)) {
          // Points are in a line
          //Debug("Skipping degenerate case (" << iX << "," << iY << " " << jX << "," << jY << " " << kX << "," << kY << ")");
          continue;
        }

        // Compute the circle that is formed by the features at indices i, j, and k
        float pX, pY;
        if(dYA == 0) {
          continue;
          pX = mXA;
          if(dXB == 0) {
            pY = mYB;
          } else {
            pY = mYB + ((mXB - pX) / (dYB / dXB));
          }
        } else if(dYB == 0) {
          continue;
          pX = mXB;
          if(dXA == 0) {
            pY = mYA;
          } else {
            pY = mYA + ((mXA - pX) / (dYA / dXA));
          }
        } else if(dXA == 0) {
          continue;
          pY = mYA;
          pX = ((dYB / dXB) * (mYB - pY)) + mXB;
        } else if(dXB == 0) {
          continue;
          pY = mYB;
          pX = ((dYA / dXA) * (mYA - pY)) + mXA;
        } else {
          float sA = dYA / dXA,
                sB = dYB / dXB;
          pX = ((sA * sB * (mYA - mYB)) - (sA * mXB) + (sB * mXA)) / (sB - sA);
          pY = mYA - ((pX - mXA) / sA);
        }

        if(!isfinite(pX) || !isfinite(pY)) {
          //Debug("Points are sufficiently parallel that the circle they form exceeds floating point capacity, skipping");
          continue;
        }

        float rX = iX - pX;
        float rY = iY - pY;
        float rSquared = (rX*rX) + (rY*rY);
/*
        Debug("Circle formed by features at " <<
              iX << "," << iY << " " <<
              jX << "," << jY << " " <<
              kX << "," << kY << " is centered at " <<
              pX << "," << pY << " with squared radius " << rSquared);
*/

        bool isDelaunay = true;
        // Determine if any other points lie within this circle
        for(int m = 0; m < numFeatures; m++) {
          if(m == i || m == j || m == k) { continue; }
          int mX = features[m]->getX();
          int mY = features[m]->getY();
          float dM = mX - pX;
          float dY = mY - pY;
          float mRSquared = (dM * dM) + (dY * dY);
          if(mRSquared < rSquared) {
            // Point lies within the circle, this triangle is non-delaunay
            isDelaunay = false;
            //Debug("Feature at " << mX << "," << mY << " violates Delaunay constraints");
            break;
          }
        }
        if(isDelaunay) {
          // This triangle is delaunay, add its edges
          //Debug("Triangle found to be delaunay");
          connections.insert(make_pair(features[i], features[j]));
          connections.insert(make_pair(features[i], features[k]));
          connections.insert(make_pair(features[j], features[k]));
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
  // Due to the way we add edges in the delaunay triangulation, it's expected for there to be quite a few redundant connections in the list
  // The use of sets deals with this to make sure we don't wind up with duplicated connections
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
