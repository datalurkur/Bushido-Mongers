#ifndef SECTIONED_DATA_H
#define SECTIONED_DATA_H

#include "util/packing.h"
#include "util/log.h"

#include <map>
#include <list>
#include <string>
#include <new>

using namespace std;

class BadSectionDataException : public exception {
  virtual const char* what() const throw() { return "Section data corrupt or invalid"; }
};
class DuplicateSectionException : public exception {
  virtual const char* what() const throw() { return "Duplicate section IDs are not supported"; }
};

typedef unsigned int SectionSize;

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
  typedef typename SectionMap::const_iterator const_iterator;

public:
  SectionedData();
  ~SectionedData();

  void addSection(T id, const void* data, unsigned int size);
  template <typename S>
  void addSection(T id, const S& data);
  template <typename S>
  void addSubSections(T id, const SectionedData<S>& section);
  template <typename S>
  void addListSection(T id, const list<S>& list);
  void addStringListSection(T id, const list<string>& list);

  bool getSection(T id, void** data, unsigned int& size) const;
  template <typename S>
  bool getSection(T id, S& data) const;
  template <typename S>
  bool getSubSections(T id, SectionedData<S>& section) const;
  template <typename S>
  bool getListSection(T id, list<S>& list) const;
  bool getStringListSection(T id, list<string>& list) const;

  void debug() const;

  void unpack(const void* data, unsigned int size);
  void pack(void* data, unsigned int size) const;
  unsigned int getPackedSize() const;

  iterator begin();
  const_iterator begin() const;
  iterator end();
  const_iterator end() const;

private:
  SectionMap _sections;
};

template <typename T>
void SectionedData<T>::debug() const {
  Info("SectionedData contains " << _sections.size() << " sections");
  for(auto& section : _sections) {
    Info("\tSection " << section.first << " contains " << section.second.size << " bytes");
  }
}

template <typename T>
void SectionedData<T>::unpack(const void* data, unsigned int size) {
  unsigned int i = 0;
  while(i < size) {
    T id;
    ReadFromBuffer<T>(data, size, i, id);

    SectionSize dataSize;
    ReadFromBuffer<SectionSize>(data, size, i, dataSize);

    if(size - i < dataSize) {
      throw BadSectionDataException();
    }

    addSection(id, &((char*)data)[i], dataSize);
    i += dataSize;
  }
}

template <typename T>
void SectionedData<T>::pack(void* data, unsigned int size) const {
  unsigned int offset = 0;
  for(auto& section : _sections) {
    WriteToBuffer<T>(data, size, offset, section.first);
    WriteToBuffer<SectionSize>(data, size, offset, section.second.size);
    WriteToBuffer(data, size, offset, section.second.data, section.second.size);
  }
}

template <typename T>
unsigned int SectionedData<T>::getPackedSize() const {
  unsigned int size = 0;
  for(auto& section : _sections) {
    size += section.second.size + sizeof(T) + sizeof(SectionSize);
  }
  return size;
}

template <typename T>
SectionedData<T>::SectionedData() {}

template <typename T>
SectionedData<T>::~SectionedData() {
  for(auto& section : _sections) {
    free(section.second.data);
  }
}

template <typename T>
void SectionedData<T>::addSection(T id, const void* data, unsigned int size) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    DataSection<T> section;
    section.size = size;
    section.data = 0;
    section.data = malloc(size);
    if(!section.data) { throw bad_alloc(); }
    memcpy(section.data, data, size);
    _sections[id] = section;
  } else {
    throw DuplicateSectionException();
  }
}

template <typename T>
template <typename S>
void SectionedData<T>::addSection(T id, const S& value) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    DataSection<T> section;
    section.size = sizeof(S);
    section.data = 0;
    section.data = malloc(sizeof(S));
    if(!section.data) { throw bad_alloc(); }
    memcpy(section.data, &value, sizeof(S));
    _sections[id] = section;
  } else {
    throw DuplicateSectionException();
  }
}

template <typename T>
template <typename S>
void SectionedData<T>::addSubSections(T id, const SectionedData<S>& section) {
  unsigned int sectionSize = section.getPackedSize();
  void* sectionData = malloc(sectionSize);
  if(!sectionData) { throw bad_alloc(); }
  section.pack(sectionData, sectionSize);

  DataSection<T> _section;
  _section.size = sectionSize;
  _section.data = sectionData;
  _sections[id] = _section;
}

template <typename T>
template <typename S>
void SectionedData<T>::addListSection(T id, const list<S>& list) {
  unsigned int sectionSize = list.size() * sizeof(S);
  void* sectionData = malloc(sectionSize);
  if(!sectionData) { throw bad_alloc(); }

  unsigned int i = 0;
  for(string& item : list) {
    ((S*)sectionData)[i] = item;
    i++;
  }
  DataSection<T> _section;
  _section.size = sectionSize;
  _section.data = sectionData;
  _sections[id] = _section;
}

template <typename T>
void SectionedData<T>::addStringListSection(T id, const list<string>& list) {
  unsigned int sectionSize = 0;
  // I don't begin to understand why clang insists on me putting std:: here.  Do namespaces and templates not get along these days?
  for(string item : list) {
    sectionSize += item.length() + sizeof(unsigned short);
  }
  void* sectionData = malloc(sectionSize);
  if(!sectionData) { throw bad_alloc(); }

  unsigned int offset = 0;
  for(string item : list) {
    WriteToBuffer<unsigned short>(sectionData, sectionSize, offset, item.length());
    WriteToBuffer(sectionData, sectionSize, offset, item.c_str(), item.length());
  }
  DataSection<T> _section;
  _section.size = sectionSize;
  _section.data = sectionData;
  _sections[id] = _section;
}

template <typename T>
bool SectionedData<T>::getSection(T id, void** data, unsigned int& size) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
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
bool SectionedData<T>::getSection(T id, S& value) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  } else {
    if(itr->second.size != sizeof(S)) {
      throw BadSectionDataException();
    }
    value = *(S*)itr->second.data;
    return true;
  }
}

template <typename T>
template <typename S>
bool SectionedData<T>::getSubSections(T id, SectionedData<S>& section) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  } else {
    section.unpack(itr->second.data, itr->second.size);
    return true;
  }
}

template <typename T>
template <typename S>
bool SectionedData<T>::getListSection(T id, list<S>& list) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  }
  unsigned int numItems = itr->second.size / sizeof(S);
  for(unsigned int i = 0; i < numItems; i++) {
    list.push_back(((S*)itr->second.data)[i]);
  }
  return true;
}

template <typename T>
bool SectionedData<T>::getStringListSection(T id, list<string>& list) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  }
  unsigned int offset = 0;
  while(offset < itr->second.size) {
    unsigned short stringLength;
    ReadFromBuffer<unsigned short>(itr->second.data, itr->second.size, offset, stringLength);
    void* stringData = calloc(stringLength+1, sizeof(char));
    ReadFromBuffer(itr->second.data, itr->second.size, offset, stringData, stringLength);
    list.push_back(string((char*)stringData));
  }
  return true;
}

template <typename T>
typename SectionedData<T>::iterator SectionedData<T>::begin() { return _sections.begin(); }

template <typename T>
typename SectionedData<T>::const_iterator SectionedData<T>::begin() const { return _sections.begin(); }

template <typename T>
typename SectionedData<T>::iterator SectionedData<T>::end() { return _sections.end(); }

template <typename T>
typename SectionedData<T>::const_iterator SectionedData<T>::end() const { return _sections.end(); }

#endif
