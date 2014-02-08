#ifndef CONTAINER_H
#define CONTAINER_H

#include "game/bobject.h"

#include <list>

using namespace std;

class Container {
public:
  Container();
  ~Container();

  bool addContents(BObject* object);
  bool removeContents(BObject* object);

protected:
  ObjectMap _contents;
};

#endif
