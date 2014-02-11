#include "game/protofactory.h"
#include "game/atomicbobject.h"
#include "game/complexbobject.h"
#include "util/sectioneddata.h"

bool UnpackProto(ProtoBObject** object, const void* data, unsigned int size) {
  // Instantiate and unpack the section data
  SectionedData<ObjectSectionType> sections;
  if(!sections.unpack(data, size)) {
    Error("Failed to unpack section data");
    return false;
  }
  // Debug print
  sections.debug();

  // Get the object type and check it for sanity
  BObjectType type;
  if(!sections.getSection<BObjectType>(TypeSection, type)) {
    Error("Failed to extract proto section type");
    return false;
  }
  if(type <= FirstObjectType || type >= LastObjectType) {
    Error("Invalid proto section type " << type);
    return false;
  }

  // Use the type to invoke the appropriate constructor
  bool ret;
  switch(type) {
  case AtomicType:
    (*object) = new ProtoAtomicBObject();
    break;
  case ComplexType:
    (*object) = new ProtoComplexBObject();
    break;
  default:
    Error("Proto unpacking not implemented for object type " << (*object)->type);
    return false;
  }

  // Unpack the object data and return
  if(!(*object)->unpack(sections)) {
    Error("Failed to unpack object data");
    delete (*object);
    return false;
  }
  return true;
}

bool PackProto(const ProtoBObject* object, void** data, unsigned int& size) {
  // Start the section data for the object, and add its type
  SectionedData<ObjectSectionType> sections;
  sections.addSection<BObjectType>(TypeSection, object->type);

  // Allow the object internals to pack various data objects into the section data
  if(!object->pack(sections)) { return false; }

  // Get sizes and allocate memory for the section data
  size = sections.getPackedSize();
  (*data) = malloc(size);
  if(!*data) {
    Error("Failed to allocate memory for object data");
  }

  // Pack the section data and return
  if(!sections.pack(*data, size)) {
    free(*data);
    return false;
  }
  return true;
}

bool UnpackExtensionProto(ProtoBObjectExtension** extension, const void* data, unsigned int size) {
  #pragma message "TODO : Write extension unpacking code"
  return true;
}

bool PackExtensionProto(const ProtoBObjectExtension* extension, void** data, unsigned int& size) {
  #pragma message "TODO : Write extension packing code"
  return true;
}
