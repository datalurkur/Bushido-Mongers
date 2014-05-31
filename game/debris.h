#ifndef DEBRIS_H
#define DEBRIS_H

#include "game/complexbobject.h"

// Pieces left behind from the partial destruction of a complex bobject
class Debris: public ComplexBObject {
public:
  Debris(BObjectManager* manager, ComplexBObject* parent, const ObjectSet& components);
  ~Debris();

private:
  BObjectID _sourceObject;
};

#endif
