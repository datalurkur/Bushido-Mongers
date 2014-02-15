#ifndef COMPOSITE_BOBJECT_H
#define COMPOSITE_BOBJECT_H

#include "util/sectioneddata.h"

#include "game/bobject.h"
#include "game/bobjecttypes.h"

class ProtoCompositeBObject : public ProtoBObject {
public:
  ProtoCompositeBObject();
  virtual ~ProtoCompositeBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  list<string> layers;
};

class CompositeBObject : public BObject {
public:
  CompositeBObject(BObjectID id, const ProtoCompositeBObject* proto);

  virtual bool atCreation(BObjectManager* manager);
  virtual void atDestruction(BObjectManager* manager);

  float getWeight() const;

private:
  // After object creation, all layers are explicit and can be flattened into a single list
  BObjectList _layers;
};

#endif
