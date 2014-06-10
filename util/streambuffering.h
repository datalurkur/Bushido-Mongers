#ifndef STREAMBUFFERING_H
#define STREAMBUFFERING_H

#include "util/assertion.h"
#include "util/stringhelper.h"
#include "util/vector.h"

#include <map>
#include <set>
#include <sstream>

using namespace std;

// Generic numeric type buffering
template <typename T>
void bufferToStream(ostringstream& stream, const T& value) {
  stream.write((char*)&value, sizeof(T));
}

template <typename T>
void bufferFromStream(istringstream& stream, T& value) {
  stream.read((char*)&value, sizeof(T));
  ASSERT(stream, "Failed to read value from stream");
}

// vector buffering
template <typename T>
void bufferToStream(ostringstream& stream, const VectorBase<T>& v) {
  bufferToStream(stream, v.x);
  bufferToStream(stream, v.y);
}

template <typename T>
void bufferFromStream(istringstream& stream, VectorBase<T>& v) {
  bufferFromStream(stream, v.x);
  bufferFromStream(stream, v.y);
}

// std::set buffering
template <typename T>
void bufferToStream(ostringstream& stream, const set<T>& s) {
  bufferToStream(stream, s.size());
  for(auto i : s) {
    bufferToStream(stream, i);
  }
}

template <typename T>
void bufferFromStream(istringstream& stream, set<T>& s) {
  size_t size;
  bufferFromStream(stream, size);
  for(size_t i = 0; i < size; i++) {
    T val;
    bufferFromStream(stream, val);
    s.insert(val);
  }
}

// std::map buffering
template <typename T, typename S>
void bufferToStream(ostringstream& stream, const map<T,S>& m) {
  bufferToStream(stream, m.size());
  for(auto i : m) {
    bufferToStream(stream, i.first);
    bufferToStream(stream, i.second);
  }
}

template <typename T, typename S>
void bufferFromStream(istringstream& stream, map<T,S>& m) {
  size_t size;
  bufferFromStream(stream, size);
  for(size_t i = 0; i < size; i++) {
    T key;
    S val;
    bufferFromStream(stream, key);
    bufferFromStream(stream, val);
    m.insert(make_pair(key, val));
  }
}

#endif
