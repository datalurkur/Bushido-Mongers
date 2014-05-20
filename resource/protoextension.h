#ifndef PROTO_EXTENSION_H
#define PROTO_EXTENSION_H

#include "game/bobjecttypes.h"
#include "util/sectioneddata.h"

class ProtoBObjectExtension {
public:
  ProtoBObjectExtension(ExtensionType t);

  virtual void pack(SectionedData<AttributeSectionType>& sections) const = 0;
  virtual bool unpack(const SectionedData<AttributeSectionType>& sections) = 0;

  ExtensionType type;
};

#endif
