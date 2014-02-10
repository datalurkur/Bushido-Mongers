#include "resource/raw.h"

#include "util/log.h"
#include "util/packing.h"
#include "util/sectioneddata.h"

#include "game/atomicbobject.h"
#include "game/complexbobject.h"
#include "game/protofactory.h"

bool Raw::unpack(const void* data, unsigned int size) {
  RawHeader header;
  unsigned int offset = 0;
  if(!ReadFromBuffer<RawHeader>(data, size, offset, header)) {
    Error("Failed to read raw header");
    return false;
  }
  if(header.magic != MAGIC) {
    Error("Raw magic string does not match");
    return false;
  }
  if(header.version > VERSION) {
    Error("Version exceeds reader capability");
    return false;
  }

  SectionedData<string> sections;
  if(!sections.unpack(&((char*)data)[offset], size-offset)) { return false; }

  SectionedData<string>::iterator itr;
  for(itr = sections.begin(); itr != sections.end(); itr++) {
    ProtoBObject* object;
    if(!UnpackProto(&object, itr->second.data, itr->second.size)) {
      Error("Failed to load object " << itr->first);
      return false;
    }
    _objectMap[itr->first] = object;
  }

  return true;
}

bool Raw::pack(void** data, unsigned int& size) const {
  RawHeader header;
  header.magic = MAGIC;
  header.version = VERSION;

  SectionedData<string> sections;
  ProtoMap::const_iterator itr;
  for(itr = _objectMap.begin(); itr != _objectMap.end(); itr++) {
    void* objectData;
    unsigned int objectDataSize;
    if(!PackProto(itr->second, &objectData, objectDataSize)) { return false; }
    if(!sections.addSection(itr->first, objectData, objectDataSize)) { return false; }
    free(objectData);
  }

  unsigned int sectionDataSize = sections.getPackedSize();
  size = sectionDataSize + sizeof(RawHeader);

  (*data) = malloc(size);
  if(!(*data)) {
    Error("Failed to allocate memory for packed raw data");
    return false;
  }
  memcpy(*data, &header, sizeof(RawHeader));
  if(!sections.pack(&((char*)*data)[sizeof(RawHeader)], sectionDataSize)) {
    Error("Failed to get packed section data for raw");
    free(*data);
    return false;
  }

  return true;
}

Raw::Raw() {}

Raw::~Raw() {
  for(ProtoMap::iterator itr = _objectMap.begin(); itr != _objectMap.end(); itr++) {
    delete itr->second;
  }
  _objectMap.clear();
}

unsigned int Raw::getNumObjects() const { return _objectMap.size(); }

void Raw::getObjectNames(list<string>& names) const {
  for(ProtoMap::const_iterator itr = _objectMap.begin(); itr != _objectMap.end(); itr++) {
    names.push_back(itr->first);
  }
}

ProtoBObject* Raw::getObject(const string& name) const {
  ProtoMap::const_iterator itr = _objectMap.find(name);
  if(itr == _objectMap.end()) { return 0; }
  else { return itr->second; }
}

bool Raw::addObject(const string& name, ProtoBObject* object) {
  ProtoMap::iterator itr = _objectMap.find(name);
  if(itr == _objectMap.end()) {
    _objectMap[name] = object;
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

bool Raw::cloneObject(const string& source, const string& dest) {
  ProtoMap::iterator destItr = _objectMap.find(dest);
  ProtoMap::iterator srcItr = _objectMap.find(source);
  if(destItr == _objectMap.end() && srcItr != _objectMap.end()) {
    return true;
  } else { return false; }
}
