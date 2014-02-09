#include "util/packing.h"

bool ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, void* data, unsigned int dataSize) {
  if(offset + dataSize > size) { return false; }
  memcpy(data, &((char*)buffer)[offset], dataSize);
  offset += dataSize;
  return true;
}

bool WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const void* data, unsigned int dataSize) {
  if(offset + dataSize > size) { return false; }
  memcpy(&((char*)buffer)[offset], data, dataSize);
  offset += dataSize;
  return true;
}
