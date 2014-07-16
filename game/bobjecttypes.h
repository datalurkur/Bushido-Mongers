#ifndef BOBJECT_TYPES_H
#define BOBJECT_TYPES_H

#include "util/streambuffering.h"

typedef int BObjectID;

enum BObjectType {
  FirstObjectType = 0,
  AtomicType,
  CompositeType,
  ComplexType,
  ContainerType,
  LastObjectType
};
extern void bufferToStream(ostringstream& str, const BObjectType& val);
extern void bufferFromStream(istringstream& str, BObjectType& val);

enum ObjectSectionType {
  FirstObjectSectionType = 0,
  TypeSection,
  BaseData,
  AtomicData,
  CompositeData,
  ComplexData,
  ExtensionData,
  LastObjectSectionType
};
extern void bufferToStream(ostringstream& str, const ObjectSectionType& val);
extern void bufferFromStream(istringstream& str, ObjectSectionType& val);

enum AttributeSectionType {
  FirstAttributeSectionType = 0,
  KeywordsList,
  WeightAttribute,
  LayersList,
  ComponentMap,
  ConnectionMap,
  LastAttributeSectionType
};
extern void bufferToStream(ostringstream& str, const AttributeSectionType& val);
extern void bufferFromStream(istringstream& str, AttributeSectionType& val);

enum ExtensionType {
  FirstExtension = 0,
  LastExtension
};
extern void bufferToStream(ostringstream& str, const ExtensionType& val);
extern void bufferFromStream(istringstream& str, ExtensionType& val);

#endif
