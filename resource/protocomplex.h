#ifndef PROTO_COMPLEX_H
#define PROTO_COMPLEX_H

#include "resource/protobobject.h"

class ProtoComplexBObject : public ProtoBObject {
public:
  ProtoComplexBObject(const string& name, BObjectType t = ComplexType);
  virtual ~ProtoComplexBObject();

  virtual void pack(SectionedData<ObjectSectionType>& sections) const;
  virtual bool unpack(const SectionedData<ObjectSectionType>& sections);

  void addComponent(const string& nickname, const string& raw_type);
  void remComponent(const string& nickname);

  void addConnection(const string& first, const string& second);
  void remConnection(const string& first, const string& second);

  bool hasComponent(const string& nickname);

  map<string,string> components;
  map<string,set<string> > connections;
};

#endif
