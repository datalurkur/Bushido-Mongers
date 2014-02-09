#ifndef BOBJECT_TYPES_H
#define BOBJECT_TYPES_H

enum BObjectType {
  FirstType = 0,
  AtomicType,
  ComplexType,
  LastType
};

enum SectionType {
  FirstSection = 0,
  TypeSection,
  AtomicData,
  ComplexData,
  LastSection
};

enum AttributeType {
  FirstAttribute = 0,
  WeightAttribute,
  LastAttribute
};

enum ExtensionType {
  FirstExtension = 0,
  LastExtension
};

#endif
