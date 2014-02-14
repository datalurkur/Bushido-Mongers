#include "util/sectioneddata.h"

#include <string>

using namespace std;

template <>
void SectionedData<string>::unpack(const void* data, unsigned int size) {
  unsigned int i = 0;
  while(i < size) {
    unsigned short stringSize;
    ReadFromBuffer<unsigned short>(data, size, i, stringSize);
    void* charID = calloc(stringSize+1, sizeof(char));

    ReadFromBuffer(data, size, i, charID, stringSize);
    string id((char*)charID);
    free(charID);

    SectionSize dataSize;
    ReadFromBuffer<SectionSize>(data, size, i, dataSize);

    if(size - i < dataSize) {
      throw BadSectionDataException();
    }
    addSection(id, &((char*)data)[i], dataSize);
    i += dataSize;
  }
}

template <>
void SectionedData<string>::pack(void* data, unsigned int size) const {
  SectionMap::const_iterator itr;

  unsigned int offset = 0;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    WriteToBuffer<unsigned short>(data, size, offset, itr->first.length());
    WriteToBuffer(data, size, offset, itr->first.c_str(), itr->first.length());
    WriteToBuffer<SectionSize>(data, size, offset, itr->second.size);
    WriteToBuffer(data, size, offset, itr->second.data, itr->second.size);
  }
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
