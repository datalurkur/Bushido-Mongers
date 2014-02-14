#ifndef PACKING_H
#define PACKING_H

#include "util/log.h"
#include "util/assertion.h"

#include <stdlib.h>
#include <cstring>

using namespace std;

class BufferOverrunException : public exception {
  virtual const char* what() const throw() { return "Ran past the end of buffer"; }
};

extern void ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, void* data, unsigned int dataSize);
extern void WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const void* data, unsigned int dataSize);

template <typename T>
void ReadFromBuffer(const void* buffer, unsigned int size, unsigned int& offset, T& value) {
  if(offset + sizeof(T) > size) {
    throw BufferOverrunException();
  }
  memcpy(&value, &((char*)buffer)[offset], sizeof(T));
  offset += sizeof(T);
}
template <typename T>
void WriteToBuffer(void* buffer, unsigned int size, unsigned int& offset, const T& value) {
  if(offset + sizeof(T) > size) {
    throw BufferOverrunException();
  }
  memcpy(&((char*)buffer)[offset], &value, sizeof(T));
  offset += sizeof(T);
}

#endif
