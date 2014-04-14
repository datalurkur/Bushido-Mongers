#ifndef COMPLEX_H
#define COMPLEX_H

#include "game/complexbobject.h"

extern void editComplexBObject(const string& name, ProtoComplexBObject* object);
extern void editComplexComponents(const string& name, ProtoComplexBObject* object);
extern void editComplexConnections(const string& name, ProtoComplexBObject* object);

#endif
