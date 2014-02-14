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

  // Layers are defined here with an index so that explicit and generic layers can be interspersed
  map<int,string> explicitLayers;
  map<int,string> keywordLayers;
};

class CompositeBObject : public BObject {
public:
  CompositeBObject(BObjectID id, const ProtoCompositeBObject* proto);

  float getWeight() const;

private:
  // After object creation, all layers are explicit and can be flattened into a single list
  BObjectList _layers;
};

#endif
