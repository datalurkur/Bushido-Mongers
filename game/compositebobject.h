#ifndef COMPOSITE_BOBJECT_H
#define COMPOSITE_BOBJECT_H

#include "game/bobject.h"
#include "resource/protocomposite.h"

class CompositeBObject : public BObject {
public:
  CompositeBObject(BObjectManager* manager, BObjectID id, const ProtoCompositeBObject* proto);

  virtual bool atCreation();
  virtual bool atDestruction();

  float getWeight() const;

private:
  // After object creation, all layers are explicit and can be flattened into a single list
  BObjectList _layers;
};

#endif
