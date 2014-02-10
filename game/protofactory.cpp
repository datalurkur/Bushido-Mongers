#include "game/protofactory.h"
#include "game/atomicbobject.h"
#include "util/sectioneddata.h"

bool UnpackProto(ProtoBObject** object, const void* data, unsigned int size) {
  SectionedData<ObjectSectionType> sections;
  if(!sections.unpack(data, size)) {
    Error("Failed to unpack section data");
    return false;
  }
  sections.debug();

  BObjectType type;
  if(!sections.getSection<BObjectType>(TypeSection, type)) {
    Error("Failed to extract proto section type");
    return false;
  }
  if(type <= FirstObjectType || type >= LastObjectType) {
    Error("Invalid proto section type " << type);
    return false;
  }

  bool ret;
  void* sectionData;
  unsigned int sectionSize;
  switch(type) {
  case AtomicType: {
    if(!sections.getSection(AtomicData, &sectionData, sectionSize)) {
      Error("Atomic data section missing");
      return false;
    }
    SectionedData<AttributeSectionType> sections;
    sections.unpack(sectionData, sectionSize);
    (*object) = new ProtoAtomicBObject();
    ret = (*object)->unpack(sections);
  } break;
  default:
    Error("Proto unpacking not implemented for object type " << (*object)->type);
    return false;
  }

  if(!ret) { delete (*object); }

  return ret;
}

bool PackProto(const ProtoBObject* object, void** data, unsigned int& size) {
  SectionedData<ObjectSectionType> sections;

  sections.addSection<BObjectType>(TypeSection, object->type);

  bool ret;
  void* sectionData;
  unsigned int sectionSize;
  SectionedData<AttributeSectionType> objectSections;
  if(!object->pack(objectSections)) { return false; }
  if(!objectSections.pack(&sectionData, sectionSize)) { return false; }

  switch(object->type) {
  case AtomicType:
    ret = sections.addSection(AtomicData, sectionData, sectionSize);
    break;
  default:
    Error("Proto packing not implemented for object type " << object->type);
    return false;
  }

  free(sectionData);
  if(!ret) { return false; }

  return sections.pack(data, size);
}
