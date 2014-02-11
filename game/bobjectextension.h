#ifndef OBJECT_EXTENSION_H
#define OBJECT_EXTENSION_H

#include "game/bobjecttypes.h"

class ProtoBObjectExtension {
public:
  ProtoBObjectExtension(ExtensionType t);

  virtual bool pack(SectionedData<AttributeSectionType>& sections) const;
  virtual bool unpack(const SectionedData<AttributeSectionType>& sections);

  ExtensionType type;
};

class BObjectExtension {
public:

private:
};

#endif
