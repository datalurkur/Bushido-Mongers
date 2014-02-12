#ifndef PACKING_H
#define PACKING_H

#include "util/log.h"
#include "util/assertion.h"

#include <stdlib.h>
#include <cstring>

extern bool ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, void* data, unsigned int dataSize);
extern bool WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const void* data, unsigned int dataSize);

template <typename T>
bool ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, T& value) {
  if(offset + sizeof(T) > size) {
    ASSERT(0, "Attempted to read " << offset + sizeof(T) - size << " bytes past index " << offset << " in a " << size << " byte buffer");
    return false;
  }
  std::memcpy(&value, &((char*)buffer)[offset], sizeof(T));
  offset += sizeof(T);
  return true;
}
template <typename T>
bool WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const T& value) {
  if(offset + sizeof(T) > size) {
    ASSERT(0, "Attempted to write " << offset + sizeof(T) - size << " bytes past index " << offset << " in a " << size << " byte buffer");
    return false;
  }
  std::memcpy(&((char*)buffer)[offset], &value, sizeof(T));
  offset += sizeof(T);
  return true;
}

/*
#pragma message "Non-allocating versions of these need to be written"
template <typename T>
bool ReadSizeEncoded(const void* buffer, unsigned int size, unsigned int& offset, void** data) {
  T objectSize;
  if(ReadFromBuffer<T>(buffer, size, offset, objectSize) == 0) { return false; }
  (*data) = malloc(objectSize);
  if(ReadFromBuffer(buffer, size, offset, data, objectSize) == 0) { return false; }
  return true;
}
template <typename T>
extern bool PackSizeEncoded(void** buffer, unsigned int& size, const void* data, unsigned int dataSize) {
  (*buffer) = malloc(dataSize + sizeof(T));
  if(*buffer == 0) { return false; }
  std::memcpy(*buffer, &dataSize, sizeof(T));
  std::memcpy(&((char*)*buffer)[sizeof(T)], data, dataSize);
  return true;
}
*/

#endif
