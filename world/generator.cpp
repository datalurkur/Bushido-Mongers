#include "world/generator.h"
#include "util/pointquadtree.h"

#include <map>
#include <set>
#include <list>

World* WorldGenerator::CloudGenerate(int size, float sparseness) {
  // Determine the number of features the world should contain
  int numFeatures = size * sparseness / 2;
  int averageFeatureSize = 2 / sparseness;
  Debug("Generating " << numFeatures << " features in a " << size << "-sized world");

  // Generate a random point cloud
  list<Feature* > features;
  for(int i = 0; i < numFeatures; i++) {
    int x = rand() % size,
        y = rand() % size,
        r = rand() % averageFeatureSize + (averageFeatureSize / 2);
    Debug("Created a feature at (" << x << "," << y << ") with approximate size " << r);
    features.push_back(new Feature(x, y, r));
  }

  // Insert the point cloud into a quadtree structure
  // Determine the depth of the tree based on the number of objects going into it
  int depth = 0, counter = 1;
  while(counter < numFeatures) {
    depth++;
    counter <<= 1;
  }
  Debug("Creating a quadtree with depth " << depth << " to accomodate features");
  PointQuadTree<Feature*, int> tree(0, 0, size, size, depth, features);

  // Determine the connectivity of the points in the cloud
  map<Feature*, set<Feature*> > connections;
  for(auto feature : features) {
    Debug("Finding connections for feature at (" << feature->getX() << "," << feature->getY() << ") with radius " << feature->getRadius());
    // Set up our comparator
    FeatureDistanceComparator comp(feature);

    int doubleR = 2 * feature->getRadius();

    // Get all nodes within 2 radiuses of this node
    list<Feature* > nearbyFeatures;
    tree.getObjects(feature->getX() - doubleR,
                    feature->getY() - doubleR,
                    feature->getX() + doubleR,
                    feature->getY() + doubleR,
                    nearbyFeatures);

    // Sort by distance to the feature
    nearbyFeatures.sort(comp);

    // For any two features whose radiuses overlap, consider them connected
    for(auto nearby : nearbyFeatures) {
      Debug("Feature at (" << nearby->getX() << "," << nearby->getY() << ") with approximate size " << nearby->getRadius() << " is considered connected");
    }
  }

  return 0;
}
