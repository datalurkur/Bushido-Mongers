#include "util/sectioneddata.h"

#include <string>

using namespace std;

template <>
bool SectionedData<string>::unpack(const void* data, unsigned int size) {
  unsigned int i = 0;
  while(i < size) {
    unsigned short stringSize;
    if(!ReadFromBuffer<unsigned short>(data, size, i, stringSize)) {
      Error("Failed to read section ID length");
      return false;
    }
    Debug("Read string size " << stringSize);

    if(stringSize == 0) {
      Error("Invalid section ID length");
      return false;
    }

    void* charID = calloc(stringSize+1, sizeof(char));
    if(!ReadFromBuffer(data, size, i, charID, stringSize)) {
      Error("Failed to read section ID");
      return false;
    }
    string id((char*)charID);
    free(charID);

    SectionSize dataSize;
    if(!ReadFromBuffer<SectionSize>(data, size, i, dataSize)) {
      Error("Failed to read size of section " << id);
      return false;
    }

    if(size - i < dataSize) {
      Error("Failed to read data for section " << id << " (" << dataSize << " bytes)");
      return false;
    }
    if(!addSection(id, &((char*)data)[i], dataSize)) { return false; }
    i += dataSize;
  }
  return true;
}

template <>
bool SectionedData<string>::pack(void* data, unsigned int size) const {
  SectionMap::const_iterator itr;

  unsigned int offset = 0;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    if(!WriteToBuffer<unsigned short>(data, size, offset, itr->first.length())) {
      Error("Failed to write section ID length");
      return false;
    }
    if(!WriteToBuffer(data, size, offset, itr->first.c_str(), itr->first.length())) {
      Error("Failed to write section ID");
      return false;
    }
    if(!WriteToBuffer<SectionSize>(data, size, offset, itr->second.size)) {
      Error("Failed to write section size");
      return false;
    }
    if(!WriteToBuffer(data, size, offset, itr->second.data, itr->second.size)) {
      Error("Failed to write section data");
      return false;
    }
  }
  return true;
}

template <>
unsigned int SectionedData<string>::getPackedSize() const {
  unsigned int size = 0;
  SectionMap::const_iterator itr;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    unsigned int sectionSize = itr->second.size + sizeof(unsigned short) + itr->first.length() + sizeof(SectionSize);
    size += sectionSize;
  }
  return size;
}
