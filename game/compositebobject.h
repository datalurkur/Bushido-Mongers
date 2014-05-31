#ifndef COMPOSITE_BOBJECT_H
#define COMPOSITE_BOBJECT_H

#include "game/bobject.h"
#include "resource/protocomposite.h"

class CompositeBObject : public BObject {
public:
  CompositeBObject(BObjectManager* manager, const ProtoCompositeBObject* proto);
  virtual ~CompositeBObject();

  float getWeight() const;

  virtual DamageResult damage(const Damage& dmg);

private:
  // After object creation, all layers are explicit and can be flattened into a single list
  BObjectList _layers;
};

#endif
