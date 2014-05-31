#include "game/compositebobject.h"
#include "game/bobjectmanager.h"

#include <vector>
using namespace std;

CompositeBObject::CompositeBObject(BObjectManager* manager, const ProtoCompositeBObject* proto): BObject(manager, CompositeType, proto) {
  const ProtoCompositeBObject* p = (ProtoCompositeBObject*)_proto;
  for(const string& layerName : p->layers) {
    BObject* layer = _manager->createObjectFromPrototype(layerName);
    if(layer == 0) {
      Error("Failed to create layer " << layerName);
      continue;
    }
    _layers.push_back(layer);
  }
}

CompositeBObject::~CompositeBObject() {
  for(auto layer : _layers) {
    _manager->destroyObject(layer->getID());
  }
}

float CompositeBObject::getWeight() const {
  float total = 0;

  for(auto layer : _layers) { total += layer->getWeight(); }

  return total;
}

DamageResult CompositeBObject::damage(const Damage& dmg) {
  Info("Composite object taking " << dmg.amount << " damage");
  DamageResult result { 0.0f, 0.0f, false };

  Damage damageLeft(dmg);
  vector<BObject*> destroyedLayers;
  for(auto layer : _layers) {
    DamageResult layerResult = layer->damage(damageLeft);
    result.absorbed += layerResult.absorbed;
    result.remaining = layerResult.remaining;
    damageLeft.amount = layerResult.remaining;

    if(layerResult.destroyed) {
      destroyedLayers.push_back(layer);
    }
    if(damageLeft.amount == 0) { break; }
    Info("Damage punches through to a lower layer");
  }
  for(auto toDestroy : destroyedLayers) {
    #pragma message "We might send a message here to let players know a layer was destroyed"
    Info("Layer destroyed from damage");
    _layers.remove(toDestroy);
    _manager->destroyObject(toDestroy->getID());
  }
}
