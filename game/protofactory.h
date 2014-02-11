#ifndef PROTOFACTORY_H
#define PROTOFACTORY_H

#include "game/bobjecttypes.h"
#include "game/bobject.h"

extern bool UnpackProto(ProtoBObject** object, const void* data, unsigned int size);
extern bool PackProto(const ProtoBObject* object, void** data, unsigned int& size);

extern bool UnpackExtensionProto(ProtoBObjectExtension** extension, const void* data, unsigned int size);
extern bool PackExtensionProto(const ProtoBObjectExtension* extension, void** data, unsigned int& size);

#endif
