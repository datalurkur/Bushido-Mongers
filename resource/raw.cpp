#include "resource/raw.h"

#include "util/log.h"
#include "util/streambuffering.h"
#include "util/sectioneddata.h"

#include "game/atomicbobject.h"
#include "game/compositebobject.h"
#include "game/complexbobject.h"
#include "game/containerbobject.h"

bool Raw::unpack(istringstream& stream) {
  RawHeader header;
  genericBufferFromStream(stream, header);

  if(header.magic != MAGIC) {
    Error("Raw magic string does not match");
    return false;
  }
  if(header.version > VERSION) {
    Error("Version exceeds reader capability");
    return false;
  }

  SectionedData<string> sections;
  sections.unpack(stream);

  // Debug print
  //sections.debug();

  for(auto& section : sections) {
    ProtoBObject* object = unpackProto(section.first, section.second);
    if(!object) {
      Error("Failed to load object " << section.first);
      return false;
    }
    addObject(section.first, object);
  }

  return true;
}

ProtoBObject* Raw::unpackProto(const string& name, const string& objectData) {
  istringstream str(objectData);

  // Instantiate and unpack the section data
  SectionedData<ObjectSectionType> sections;
  sections.unpack(str);

  // Get the object type and check it for sanity
  BObjectType type;
  if(!sections.getSection<BObjectType>(TypeSection, type)) {
    Error("Failed to extract proto section type");
    return 0;
  }
  if(type <= FirstObjectType || type >= LastObjectType) {
    Error("Invalid proto section type " << type);
    return 0;
  }

  // Use the type to invoke the appropriate constructor
  ProtoBObject* object;
  switch(type) {
  case AtomicType:
    object = new ProtoAtomicBObject(name);
    break;
  case CompositeType:
    object = new ProtoCompositeBObject(name);
    break;
  case ComplexType:
    object = new ProtoComplexBObject(name);
    break;
  case ContainerType:
    object = new ProtoContainerBObject(name);
    break;
  default:
    Error("Proto unpacking not implemented for object type " << type);
    return 0;
  }

  // Unpack the object data and return
  if(!object->unpack(sections)) {
    Error("Failed to unpack object data");
    delete object;
    return 0;
  }
  return object;
}

bool Raw::pack(ostringstream& str) const {
  RawHeader header;
  header.magic = MAGIC;
  header.version = VERSION;
  genericBufferToStream(str, header);

  SectionedData<string> sections;
  for(auto& itr : _objectMap) {
    SectionedData<ObjectSectionType> objectSections;
    objectSections.addSection<BObjectType>(TypeSection, itr.second->type);
    itr.second->pack(objectSections);
    sections.addSection<SectionedData<ObjectSectionType> >(itr.first, objectSections);
  }
  sections.debug();
  sections.pack(str);

  return true;
}

Raw::Raw() {}

Raw::~Raw() {
  for(auto& itr : _objectMap) {
    delete itr.second;
  }
  _objectMap.clear();
}

unsigned int Raw::getNumObjects() const { return _objectMap.size(); }

void Raw::getObjectNames(list<string>& names) const {
  for(auto& itr : _objectMap) {
    names.push_back(itr.first);
  }
}

ProtoBObject* Raw::getObject(const string& name) const {
  ProtoMap::const_iterator itr = _objectMap.find(name);
  if(itr == _objectMap.end()) { return 0; }
  else { return itr->second; }
}

void Raw::getObjectsByKeyword(const string& keyword, list<ProtoBObject*> &objects) const {
  KeywordMap::const_iterator kwItr = _keywordMap.find(keyword);
  if(kwItr == _keywordMap.end()) { return; }

  #pragma message "TODO : Consider using different data structure here to make load time longer but runtime potentially more efficient"
  for(auto& object : kwItr->second) {
    objects.push_back(object);
  }
}

ProtoBObject* Raw::getRandomObjectByKeyword(const string& keyword) const {
  KeywordMap::const_iterator kwItr = _keywordMap.find(keyword);
  if(kwItr == _keywordMap.end()) { return 0; }
  set<ProtoBObject*>::const_iterator itr = kwItr->second.begin();
  advance(itr, rand() % kwItr->second.size());
  return *itr;
}

bool Raw::addObject(const string& name, ProtoBObject* object) {
  Info("Adding object " << name << " to raws");
  ProtoMap::iterator objectItr = _objectMap.find(name);
  if(objectItr == _objectMap.end()) {
    _objectMap[name] = object;
    for(auto& keyword : object->keywords) {
      _keywordMap[keyword].insert(object);
    }
    return true;
  } else { return false; }
}

bool Raw::deleteObject(const string& name) {
  ProtoMap::iterator itr = _objectMap.find(name);
  if(itr == _objectMap.end()) {
    return false;
  } else {
    free(itr->second);
    _objectMap.erase(itr);
    return true;
  }
}
