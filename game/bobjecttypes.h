#ifndef BOBJECT_TYPES_H
#define BOBJECT_TYPES_H

enum BObjectType {
  AtomicType,
  ComplexType,
  LastType
};

enum SectionType {
  TypeSection,
  AtomicData,
  ComplexData,
  LastSection
};

enum AttributeType {
  WeightAttribute,
  LastAttribute
};

enum ExtensionType {
  LastExtension
};

#endif
