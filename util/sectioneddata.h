#ifndef SECTIONED_DATA_H
#define SECTIONED_DATA_H

#include "util/packing.h"
#include "util/log.h"

#include <map>

typedef int SectionSize;

template <typename T>
struct DataSection {
  unsigned int size;
  void* data;
};

template <typename T>
class SectionedData {
public:
  typedef map<T, DataSection<T> > SectionMap;
  typedef typename SectionMap::iterator iterator;

public:
  SectionedData();
  ~SectionedData();

  bool addSection(T id, const void* data, unsigned int size);
  bool getSection(T id, void** data, unsigned int& size);

  template <typename S>
  bool addSection(T id, const S& data);

  template <typename S>
  bool getSection(T id, S& data);

  bool unpack(const void* data, unsigned int size);
  bool pack(void** data, unsigned int& size);

  iterator begin();
  iterator end();

private:
  SectionMap _sections;
};

template <typename T>
bool SectionedData<T>::unpack(const void* data, unsigned int size) {
  unsigned int i = 0;
  while(i < size) {
    T id;
    if(!ReadFromBuffer<T>(data, size, i, id)) {
      Error("Failed to read section ID");
      return false;
    }

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

template <typename T>
bool SectionedData<T>::pack(void** data, unsigned int& size) {
  unsigned int totalSize = 0;
  typename SectionMap::iterator itr;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    totalSize += itr->second.size + sizeof(T) + sizeof(SectionSize);
  }
  (*data) = malloc(totalSize);
  unsigned int offset;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    if(!WriteToBuffer<T>(data, size, offset, itr->first)) {
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

template <typename T>
SectionedData<T>::SectionedData() {}

template <typename T>
SectionedData<T>::~SectionedData() {
  typename SectionMap::iterator itr;
  for(itr = _sections.begin(); itr != _sections.end(); itr++) {
    free(itr->second.data);
  }
}

template <typename T>
bool SectionedData<T>::addSection(T id, const void* data, unsigned int size) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    DataSection<T> section;
    section.size = size;
    section.data = malloc(size);
    memcpy(section.data, data, size);
    _sections[id] = section;
    return true;
  } else {
    Error("Can't add duplicate section " << id << ", ignoring");
    return false;
  }
}

template <typename T>
bool SectionedData<T>::getSection(T id, void** data, unsigned int& size) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  } else {
    *data = itr->second.data;
    size = itr->second.size;
    return true;
  }
}

template <typename T>
template <typename S>
bool SectionedData<T>::addSection(T id, const S& value) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    DataSection<T> section;
    section.size = sizeof(S);
    section.data = malloc(sizeof(S));
    memcpy(section.data, &value, sizeof(S));
    _sections[id] = section;
    return true;
  } else {
    return false;
  }
}

template <typename T>
template <typename S>
bool SectionedData<T>::getSection(T id, S& value) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  } else {
    if(itr->second.size != sizeof(S)) {
      Error("Size mismatch for section " << id);
      return false;
    }
    value = *(S*)itr->second.data;
    return true;
  }
}

template <typename T>
typename SectionedData<T>::iterator SectionedData<T>::begin() { return _sections.begin(); }

template <typename T>
typename SectionedData<T>::iterator SectionedData<T>::end() { return _sections.end(); }

#endif
