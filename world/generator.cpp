#include "world/generator.h"
#include "util/pointquadtree.h"
#include "util/timer.h"
#include "util/geom.h"
#include "util/noise.h"
#include "util/structure.h"
#include "game/bobjectmanager.h"

#include <vector>
#include <set>
#include <sstream>
#include <math.h>

#define WORLD_SIZE 1000

World* WorldGenerator::GenerateWorld(int numFeatures, float sparseness, float connectedness, ConnectionMethod connectionMethod, BObjectManager* objectManager) {
  // Determine the number of features the world should contain
  int averageFeatureSize = max(1, (int)(WORLD_SIZE * sparseness / 2));
  int midSize = WORLD_SIZE / 2;
  float midSizeSquared = midSize * midSize;

  float maxConnectionDistance = averageFeatureSize * connectedness; 
  float maxConnDistSquared = maxConnectionDistance * maxConnectionDistance;

  Debug("Generating " << numFeatures << " features in a " << WORLD_SIZE << "-sized world");
  Debug("Average feature size " << averageFeatureSize << " and maximum connected feature distance " << maxConnectionDistance);

  // Generate a random point cloud
  vector<Feature* > features(numFeatures);

  int i;
  for(i = 0; i < numFeatures; i++) {
    int x = rand() % WORLD_SIZE,
        y = rand() % WORLD_SIZE,
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
        if(!computeCircleFromPoints(features[i]->pos,
                                    features[j]->pos,
                                    features[k]->pos,
                                    p)) {
          continue;
        }

        Vec2 r = (Vec2)features[i]->pos - p;
        float rSquared = r.magnitudeSquared();

        bool isDelaunay = true;
        // Determine if any other points lie within this circle
        for(int m = 0; m < numFeatures; m++) {
          if(m == i || m == j || m == k) { continue; }
          Vec2 d = Vec2(features[m]->pos) - p;
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
    stream << feature->pos.x << "," << feature->pos.y;
    counter++;
    string name = stream.str();

    Area* area = new Area(name, feature->pos, Vec2(feature->radius, feature->radius));

    #pragma message "Do interesting area type generation"
    // ============ BEGIN HACK =============
    // For now, hack in a cave area descriptor and use it to generate caves statically
    AreaDescriptor desc("cave");
    desc.isOutdoors = false;
    desc.objectDensity = 0.2f;
    desc.peripheralObjects.insert("rock");
    // ============  END HACK  =============

    GenerateArea(area, desc, objectManager);

    world->addArea(area);
    feature->area = area;
  }

  // Add the connections to the world
  for(auto connection : connections) {
    bool valid = true;
    switch(connectionMethod) {
    case MaxDistance: {
      IVec2 d = connection.first->pos - connection.second->pos;
      if(d.magnitudeSquared() >= maxConnDistSquared) { valid = false; }
    } break;
    case Centralization: {
      IVec2 d = connection.first->pos - connection.second->pos;
      float distanceRatio = (midSizeSquared - (d.magnitudeSquared() / 2)) / midSizeSquared;
      if((float)rand() / RAND_MAX > (connectedness + distanceRatio) / 2) { valid = false; }
    }
    case Random:
      if((float)rand() / RAND_MAX > connectedness) { valid = false; }
      break;
    }
    if(valid) {
      world->addConnection(connection.first->area, connection.second->area);
    }
  }

  return world;
}

void WorldGenerator::PlaceAreaTransitions(Area* area) {
  for(string connectedName : area->getConnections()) {
    // Determine the unit vector that points in the direction of the connected area
  }
}

void WorldGenerator::GenerateArea(Area* area, const AreaDescriptor& descriptor, BObjectManager* objectManager) {
  int i, j;

  Debug("Generating " << descriptor.name << " area");

  // Construct the raw area
  if(descriptor.isConstructed) {
    if(descriptor.isOutdoors) {
      #pragma message "Write a factory for this"
    } else {
      #pragma message "Write a factory for this"
    }
  } else {
    if(descriptor.isOutdoors) {
      #pragma message "Write a factory for this"
    } else {
      CarveNatural(area, descriptor.openness, descriptor.density);
    }
  }

  // Populate the area with objects
  const Vec2& areaSize = (Vec2)area->getSize();
  Vec2 halfAreaSize = areaSize / 2.0f;

  #pragma message "Generate this using the openness value"
  int averageOpenness = 3;
  set<Vec2> wallWindow;
  for(i = 0; i < averageOpenness; i++) {
    for(j = 0; j < averageOpenness; j++) {
      if(i == j && i == 0) { continue; }
      wallWindow.insert(Vec2( i,  j));
      if(i != 0) {
        wallWindow.insert(Vec2(-i,  j));
      }
      if(j != 0) {
        wallWindow.insert(Vec2( i, -j));
      }
      if(i != 0 && j != 0) {
        wallWindow.insert(Vec2(-i, -j));
      }
    }
  }

  #pragma message "Consider other ways of doing this"
  for(i = 0; i < areaSize.x; i++) {
    for(j = 0; j < areaSize.y; j++) {
      TileBase* tile = area->getTile(Vec2(i,j));
      if(tile->getType() != Ground) { continue; }
      // Determine the potential object density at this location (based on the object sparsity)
      float ratioToCenter = (halfAreaSize - Vec2(i, j)).magnitude() / halfAreaSize.magnitude();
      float threshold = (2.0f * descriptor.objectDensity * (1.0f - descriptor.objectSparsity) * ratioToCenter) + (descriptor.objectDensity * descriptor.objectSparsity);
      float iThresh = threshold * RAND_MAX;
      //Debug("Ground at " << Vec2(i, j) << " has ratio to center " << ratioToCenter << " and object occurence threshold of " << threshold);

      #pragma message "Consider allowing multiple objects to be generated per-tile"
      if(rand() > iThresh) { continue; }

      // Determine proximity to walls
      bool nearWall = false;
      Vec2 p(i, j);
      for(auto w : wallWindow) {
        Vec2 o = p + w;
        if(o.x < 0 || o.x >= areaSize.x || o.y < 0 || o.y >= areaSize.y) { continue; }
        if(area->getTile(o)->getType() == Wall) {
          nearWall = true;
          break;
        }
      }

      // Determine the type of object to generate
      string objectType;
      if(nearWall && descriptor.peripheralObjects.size() > 0) {
        rand(descriptor.peripheralObjects, objectType);
      } else if(descriptor.prominentObjects.size() > 0) {
        rand(descriptor.prominentObjects, objectType);
      } else {
        continue;
      }

      // Create the object
      BObject* newObject = objectManager->createObjectFromPrototype(objectType);
      if(!newObject) {
        Error("Failed to create " << objectType);
        continue;
      }

      // Set the object's initial location
      newObject->setLocation(tile);
    }
  }
}

void WorldGenerator::CarveNatural(Area* area, float openness, float density) {
  Perlin p(256);
  Vec2 scalar = (Vec2)area->getSize() / (32 * density);
  double cutoff = 0.5 - openness;
  Vec2 center = (Vec2)area->getSize() / 2.0f;
  double maxRadiusSquared = center.magnitudeSquared();
  const Vec2& areaSize = (Vec2)area->getSize();

  for(int i = 0; i < areaSize.x; i++) {
    for(int j = 0; j < areaSize.y; j++) {
      Vec2 coords(i, j);
      Vec2 nCoords = coords / scalar;
      Vec2 offset = coords - center;
      float adjust = offset.magnitudeSquared() / maxRadiusSquared;
      double pValue = p.noise3(nCoords.x, nCoords.y, 0.5) - adjust;
      if(pValue > cutoff) {
        area->setTile(coords, new Tile(area, coords, TileType::Ground));
      } else {
        area->setTile(coords, new Tile(area, coords, TileType::Wall));
      }
    }
  }

/*
  map<int, set<Vec2>> grouped;
  ParseAreas(area, grouped);
*/
}

void WorldGenerator::CarveHallways(Area* area, float density) {
}

void WorldGenerator::ParseAreas(Area* area, map<int, set<IVec2> >& grouped) {
  const IVec2& areaSize = area->getSize();
  int* groups = (int*)calloc(areaSize.x * areaSize.y, sizeof(int));

#define GROUP(i,j) groups[((i) * (int)areaSize.y) + (j)]

  int groupCount = 1;
  int i, j;
  for(i = 0; i < areaSize.x; i++) {
    for(j = 0; j < areaSize.y; j++) {
      //Debug("Inspecting tile at " << i << "," << j);
      if(area->getTile(IVec2(i, j))->getType() == TileType::Wall) {
        //Debug("Tile is a wall, skipping");
        GROUP(i, j) = -1;
        continue;
      }

      int temp;
      list<int> adjacentGroups;

#define PUSH_GROUP(i,j) \
  do { \
    temp = GROUP(i,j); \
    if(temp > 0) { \
      adjacentGroups.push_back(temp); \
    } \
  } while(false)

      if(i > 0) {
        PUSH_GROUP(i - 1, j);
      }
      if(i < (areaSize.x - 1)) {
        PUSH_GROUP(i + 1, j);
      }
      if(j > 0) {
        PUSH_GROUP(i, j - 1);
      }
      if(j < (areaSize.y - 1)) {
        PUSH_GROUP(i, j + 1);
      }

#undef PUSH_GROUP

      if(adjacentGroups.size() == 0) {
        int newGroup = groupCount++;
        //Debug("No groups adjacent, starting group " << newGroup);
        // This node is not surrounded by any existing groups, create a new one
        GROUP(i, j) = newGroup;
        grouped.insert(make_pair(newGroup, set<IVec2> { IVec2(i, j) }));
        continue;
      }

      // This algorithm could probably use some tuning
      adjacentGroups.unique();
      auto itr = adjacentGroups.begin();
      int lowestGroup = *(itr++);
      //Debug("There are " << adjacentGroups.size() << " unique groups adjacent, with group " << lowestGroup << " being the lowest.");

      // Add this node to the lowest group
      GROUP(i, j) = lowestGroup;
      grouped[lowestGroup].insert(IVec2(i, j));
      //Debug("Group " << lowestGroup << " now contains " << grouped[lowestGroup].size() << " nodes");

      // Merge any groups that this node joins
      for(; itr != adjacentGroups.end(); itr++) {
        //Debug("Merging group " << *itr << " with " << lowestGroup);
        int debugCounter = 0;
        for(auto subNode : grouped[*itr]) {
          GROUP((int)subNode.x, (int)subNode.y) = lowestGroup;
          debugCounter++;
        }
        //Debug(debugCounter << " nodes merged");
        grouped[lowestGroup].insert(grouped[*itr].begin(), grouped[*itr].end());
        grouped.erase(*itr);
      }
    }
  }

#undef GROUP

  free(groups);
}
