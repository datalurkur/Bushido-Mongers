#ifndef CONTAINER_H
#define CONTAINER_H

#include "game/bobject.h"

#include <list>

using namespace std;

class Container {
public:
  Container();
  ~Container();

  bool addContent(BObject* object);
  bool removeContent(BObject* object);

protected:
  BObjectMap _contents;
};

#endif
