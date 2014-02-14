#include "util/packing.h"

void ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, void* data, unsigned int dataSize) {
  if(offset + dataSize > size) {
    throw BufferOverrunException();
  }
  memcpy(data, &((char*)buffer)[offset], dataSize);
  offset += dataSize;
}

void WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const void* data, unsigned int dataSize) {
  if(offset + dataSize > size) {
    throw BufferOverrunException();
  }
  memcpy(&((char*)buffer)[offset], data, dataSize);
  offset += dataSize;
}
