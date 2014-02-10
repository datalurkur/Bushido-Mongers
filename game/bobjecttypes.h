#ifndef BOBJECT_TYPES_H
#define BOBJECT_TYPES_H

enum BObjectType {
  FirstObjectType = 0,
  AtomicType,
  ComplexType,
  LastObjectType
};

enum ObjectSectionType {
  FirstObjectSectionType = 0,
  TypeSection,
  AtomicData,
  ComplexData,
  LastObjectSectionType
};

enum AttributeSectionType {
  FirstAttributeSectionType = 0,
  WeightAttribute,
  ExtensionData,
  LastAttributeSectionType
};

enum ExtensionType {
  FirstExtension = 0,
  LastExtension
};

#endif
