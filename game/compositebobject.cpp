#include "game/compositebobject.h"
#include "game/bobjectmanager.h"

ProtoCompositeBObject::ProtoCompositeBObject(): ProtoBObject(CompositeType) {}
ProtoCompositeBObject::~ProtoCompositeBObject() {}

void ProtoCompositeBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoBObject::pack(sections);

  SectionedData<AttributeSectionType> compositeData;
  compositeData.addStringListSection(LayersList, layers);

  sections.addSubSections(CompositeData, compositeData);
}

bool ProtoCompositeBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoBObject::unpack(sections)) { return false; }

  SectionedData<AttributeSectionType> compositeData;
  if(!sections.getSubSections(CompositeData, compositeData)) { return false; }

  if(!compositeData.getStringListSection(LayersList, layers)) { return false; }

  return true;
}

CompositeBObject::CompositeBObject(BObjectManager* manager, BObjectID id, const ProtoCompositeBObject* proto): BObject(manager, CompositeType, id, proto) {}

bool CompositeBObject::atCreation() {
  if(!BObject::atCreation()) { return false; }

  bool ret = true;
  const ProtoCompositeBObject* p = (ProtoCompositeBObject*)_proto;
  for(const string& layerName : p->layers) {
    BObject* layer = _manager->createObject(layerName);
    if(layer == 0) {
      ret = false;
      break;
    }
    _layers.push_back(layer);
  }

  if(!ret) {
    Error("Failed to create layers for composite object");
    for(auto layer : _layers) {
      _manager->destroyObject(layer->getID());
    }
    return false;
  }

  return true;
}

bool CompositeBObject::atDestruction() {
  if(!BObject::atDestruction()) { return false; }
  for(auto layer : _layers) {
    _manager->destroyObject(layer->getID());
  }
  return true;
}

float CompositeBObject::getWeight() const {
  float total = 0;

  for(auto layer : _layers) { total += layer->getWeight(); }

  return total;
}
