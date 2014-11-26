#ifndef STREAMBUFFERING_H
#define STREAMBUFFERING_H

#include "util/assertion.h"
#include "util/stringhelper.h"
#include "util/vector.h"

#include <list>
#include <map>
#include <set>
#include <sstream>

using namespace std;

typedef int32_t invariant_size;

class EndOfStreamException : public exception {
  virtual const char* what() const throw() { return "Prematurely reached the end of the stream"; }
};

// Generic numeric type buffering
template <typename T>
void genericBufferToStream(ostringstream& stream, const T& value) {
  stream.write((char*)&value, sizeof(T));
}

template <typename T>
void genericBufferFromStream(istringstream& stream, T& value) {
  stream.read((char*)&value, sizeof(T));
  if(!stream) { throw EndOfStreamException(); }
}

// Basic type buffering
// We define these explicitly to avoid complex types being lumped into overly simplistic buffering functions
extern void bufferToStream(ostringstream& stream, const char& value);
extern void bufferFromStream(istringstream& stream, char& value);
extern void bufferToStream(ostringstream& stream, const short& value);
extern void bufferFromStream(istringstream& stream, short& value);
extern void bufferToStream(ostringstream& stream, const int& value);
extern void bufferFromStream(istringstream& stream, int& value);
extern void bufferToStream(ostringstream& stream, const float& value);
extern void bufferFromStream(istringstream& stream, float& value);
extern void bufferToStream(ostringstream& stream, const double& value);
extern void bufferFromStream(istringstream& stream, double& value);
extern void bufferToStream(ostringstream& stream, const size_t& value);
extern void bufferFromStream(istringstream& stream, size_t& value);

// std::string buffering
extern void bufferToStream(ostringstream& stream, const string& value);
extern void bufferFromStream(istringstream& stream, string& value);

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

// std::list buffering
template <typename T>
void bufferToStream(ostringstream& stream, const list<T>& l) {
  bufferToStream(stream, l.size());
  for(auto i : l) {
    bufferToStream(stream, i);
  }
}
template <typename T>
void bufferFromStream(istringstream& stream, list<T>& l) {
  invariant_size size;
  bufferFromStream(stream, size);
  for(invariant_size i = 0; i < size; i++) {
    T val;
    bufferFromStream(stream, val);
    l.push_back(val);
  }
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
  invariant_size size;
  bufferFromStream(stream, size);
  for(invariant_size i = 0; i < size; i++) {
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
  invariant_size size;
  bufferFromStream(stream, size);
  for(invariant_size i = 0; i < size; i++) {
    T key;
    S val;
    bufferFromStream(stream, key);
    bufferFromStream(stream, val);
    m.insert(make_pair(key, val));
  }
}

#endif
