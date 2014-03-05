#include "world/generator.h"
#include "util/pointquadtree.h"

#include <vector>
#include <set>

World* WorldGenerator::CloudGenerate(int size, float sparseness) {
  // Determine the number of features the world should contain
  int numFeatures = size * sparseness / 2;
  int averageFeatureSize = 2 / sparseness;
  Debug("Generating " << numFeatures << " features in a " << size << "-sized world");

  // Generate a random point cloud
  vector<Feature* > features(numFeatures);
  int i;
  for(i = 0; i < numFeatures; i++) {
    int x = rand() % size,
        y = rand() % size,
        r = rand() % averageFeatureSize + (averageFeatureSize / 2);
    Debug("Created a feature at (" << x << "," << y << ") with approximate size " << r);
    features[i] = new Feature(x, y, r);
  }

  // Do a *really* dumb and inefficient delaunay triangulation of the points
  set<pair<Feature*, Feature*> > connections;
  int triangleCount = 0,
      permutationCount = 0;
  int j, k;
  for(i = 0; i < numFeatures - 2; i++) {
    int iX = features[i]->getX(),
        iY = features[i]->getY();

    for(j = i+1; j < numFeatures - 1; j++) {
      int jX = features[j]->getX(),
          jY = features[j]->getY();
      int dXA = jX - iX,
          dYA = jY - iY;

      for(k = j+1; k < numFeatures; k++) {
        permutationCount++;

        int kX = features[k]->getX(),
            kY = features[k]->getY();
        int dXB = kX - jX,
            dYB = kY - jY;
        float mXA = (iX + jX) / 2,
              mYA = (iY + jY) / 2,
              mXB = (jX + kX) / 2,
              mYB = (jY + kY) / 2;

        // Compute the circle that is formed by the features at indices i, j, and k
        float pX, pY;
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
          float sA = (float)dYA / dXA,
                sB = (float)dYB / dXB;
          pX = ((sA * sB * (mYA - mYB)) - (sA * mXB) + (sB * mXA)) / (sB - sA);
          pY = mYA - ((pX - mXA) / sA);
        }

        float rX = iX - pX;
        float rY = iY - pY;
        float rSquared = (rX*rX) + (rY*rY);
        Debug("Circle formed by features at " <<
              iX << "," << iY << " " <<
              jX << "," << jY << " " <<
              kX << "," << kY << " is centered at " <<
              pX << "," << pY << " with squared radius " << rSquared);

        bool isDelaunay = true;
        // Determine if any other points lie within this circle
        for(int m = 0; m < numFeatures; m++) {
          if(m == i || m == j || m == k) { continue; }
          int mX = features[m]->getX();
          int mY = features[m]->getY();
          float dM = mX - pX;
          float dY = mY - pY;
          if((dM * dM) + (dY * dY) < rSquared) {
            // Point lies within the circle, this triangle is non-delaunay
            isDelaunay = false;
            Debug("Feature at " << mX << "," << mY << " violates Delaunay constraints");
            break;
          }
        }
        if(isDelaunay) {
          // This triangle is delaunay, add its edges
          Debug("Triangle found to be delaunay");
          connections.insert(pair<Feature*, Feature*>(features[i], features[j]));
          connections.insert(pair<Feature*, Feature*>(features[i], features[k]));
          connections.insert(pair<Feature*, Feature*>(features[j], features[k]));
          triangleCount++;
        }
      }
    }
  }
  Debug("Found " << triangleCount << " valid Delaunay triangles based on " << permutationCount << " possible triangles");

  // Now that we have the features and their connectivity, create the areas and populate the world with them
  #pragma message "Complete this"

  return 0;
}
