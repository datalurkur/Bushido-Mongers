#ifndef COMPLEX_BOBJECT_H
#define COMPLEX_BOBJECT_H

#include "game/bobject.h"
#include "game/container.h"

class ProtoComplexBObject : public ProtoBObject {
public:
  list<string> components;
};

class ComplexBObject : public BObject {
public:
  ComplexBObject(ObjectID id, const ProtoComplexBObject& proto);

  float getWeight() const;

private:
  ObjectMap _components;
};

#endif
