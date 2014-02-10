#include "util/packing.h"

bool ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, void* data, unsigned int dataSize) {
  if(offset + dataSize > size) {
    Error("Attempted to read " << offset + dataSize - size << " bytes past index " << offset << " in a " << size << " byte buffer");
    return false;
  }
  memcpy(data, &((char*)buffer)[offset], dataSize);
  offset += dataSize;
  return true;
}

bool WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const void* data, unsigned int dataSize) {
  if(offset + dataSize > size) {
    Error("Attempted to write " << offset + dataSize - size << " bytes past index " << offset << " in a " << size << " byte buffer");
    return false;
  }
  memcpy(&((char*)buffer)[offset], data, dataSize);
  offset += dataSize;
  return true;
}
