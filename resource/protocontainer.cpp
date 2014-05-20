#include "resource/protocontainer.h"

ProtoContainerBObject::ProtoContainerBObject(BObjectType t): ProtoComplexBObject(t) {}
ProtoContainerBObject::~ProtoContainerBObject() {}

void ProtoContainerBObject::pack(SectionedData<ObjectSectionType>& sections) const {
  ProtoComplexBObject::pack(sections);

  #pragma message "TODO - Add container data packing"
}

bool ProtoContainerBObject::unpack(const SectionedData<ObjectSectionType>& sections) {
  if(!ProtoComplexBObject::unpack(sections)) { return false; }

  #pragma message "TODO - Add container data unpacking"
}

