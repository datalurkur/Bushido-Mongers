#ifndef SECTIONED_DATA_H
#define SECTIONED_DATA_H

#include "util/streambuffering.h"
#include "util/log.h"

#include <map>
#include <list>
#include <string>
#include <new>

using namespace std;

class DuplicateSectionException : public exception {
  virtual const char* what() const throw() { return "Duplicate section IDs are not supported"; }
};

template <typename T>
class SectionedData {
public:
  typedef map<T, string> SectionMap;
  typedef typename SectionMap::iterator iterator;
  typedef typename SectionMap::const_iterator const_iterator;

public:
  SectionedData();

  template <typename S>
  void addSection(T id, const S& data);

  template <typename S>
  bool getSection(T id, S& data) const;

  void debug() const;

  void unpack(istringstream& stream);
  void pack(ostringstream& stream) const;

  iterator begin();
  const_iterator begin() const;
  iterator end();
  const_iterator end() const;

private:
  SectionMap _sections;
};

template <typename T>
void bufferToStream(ostringstream& str, const SectionedData<T>& val) { val.pack(str); }
template <typename T>
void bufferFromStream(istringstream& str, SectionedData<T>& val) { val.unpack(str); }

template <typename T>
void SectionedData<T>::debug() const {
  Info("SectionedData contains " << _sections.size() << " sections");
  for(auto& section : _sections) {
    Info("\tSection " << section.first << " contains " << section.second.size() << " bytes");
  }
}

template <typename T>
void SectionedData<T>::unpack(istringstream& stream) {
  while(stream) {
    T id;
    try {
      bufferFromStream(stream, id);
    } catch(EndOfStreamException e) {
      break;
    }

    string sectionData;
    bufferFromStream(stream, sectionData);

    _sections[id] = sectionData;
  }
}

template <typename T>
void SectionedData<T>::pack(ostringstream& stream) const {
  for(auto section: _sections) {
    bufferToStream(stream, section.first);
    bufferToStream(stream, section.second);
  }
}

template <typename T>
SectionedData<T>::SectionedData() {}

template <typename T>
template <typename S>
void SectionedData<T>::addSection(T id, const S& value) {
  typename SectionMap::iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    ostringstream stream(ios_base::binary);
    bufferToStream(stream, value);
    _sections[id] = stream.str();
  } else {
    throw DuplicateSectionException();
  }
}

template <typename T>
template <typename S>
bool SectionedData<T>::getSection(T id, S& value) const {
  typename SectionMap::const_iterator itr = _sections.find(id);
  if(itr == _sections.end()) {
    return false;
  } else {
    istringstream stream(itr->second);
    bufferFromStream(stream, value);
    return true;
  }
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
