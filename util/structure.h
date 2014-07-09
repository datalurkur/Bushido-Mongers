#ifndef STRUCTURE_H
#define STRUCTURE_H

#include <set>

using namespace std;

template <typename T>
void rand(const set<T>& s, T& t) {
  typename set<T>::const_iterator i = s.begin();
  advance(i, rand() % s.size());
  t = *i;
}

template <typename T>
set<T> operator-(const set<T>& lhs, const set<T>& rhs) {
  set<T> ret;
  typename set<T>::const_iterator lItr = lhs.begin();
  typename set<T>::const_iterator rItr = rhs.begin();

  while(lItr != lhs.end() && rItr != rhs.end()) {
    if(*lItr < *rItr) {
      ret.insert(*lItr);
      lItr++;
    } else if(*rItr < *lItr) {
      rItr++;
    } else {
      lItr++;
      rItr++;
    }
  }
  return ret;
}

template <typename T>
ostream& operator<<(ostream& stream, set<T>& s) {
  stream << s.size();
  for(auto i : s) {
    stream << i;
  }
  return stream;
}

template <typename T>
istream& operator>>(istream& stream, set<T>& s) {
  size_t size;
  stream >> size;
  for(size_t i = 0; i < size; i++) {
    T temp;
    stream >> temp;
    s.insert(temp);
  }
  return stream;
}

template <typename S, typename T>
ostream& operator<<(ostream& stream, map<S,T>& m) {
  stream << m.size();
  for(auto pair : m) {
    stream << pair.first << pair.second;
  }
  return stream;
}

template <typename S, typename T>
istream& operator>>(istream& stream, map<S,T>& m) {
  size_t size;
  stream >> size;
  for(size_t i = 0; i < size; i++) {
    S key;
    T value;
    stream >> key >> value;
    m.insert(make_pair(key, value));
  }
  return stream;
}

template <typename T>
void symmetricDiff(const set<T>& lhs, const set<T>& rhs, set<T>& onlyInLeft, set<T>& onlyInRight, set<T>& inBoth) {
  typename set<T>::const_iterator lItr = lhs.begin();
  typename set<T>::const_iterator rItr = rhs.begin();
  while(lItr != lhs.end() && rItr != rhs.end()) {
    if(*lItr < *rItr) {
      onlyInLeft.insert(*lItr);
      lItr++;
    } else if(*rItr < *lItr) {
      onlyInRight.insert(*rItr);
      rItr++;
    } else {
      inBoth.insert(*lItr);
      lItr++;
      rItr++;
    }
  }
}

template <typename T>
void setComplement(const set<T>& lhs, const set<T>& rhs, set<T>& onlyInLeft, set<T>& complement) {
  typename set<T>::const_iterator lItr = lhs.begin();
  typename set<T>::const_iterator rItr = rhs.begin();
  if(lItr == lhs.end()) {
    complement = rhs;
  } else if(rItr == lhs.end()) {
    onlyInLeft = lhs;
  } else {
    while(lItr != lhs.end() && rItr != rhs.end()) {
      if(*lItr < *rItr) {
        onlyInLeft.insert(*lItr);
        lItr++;
      } else if(*rItr < *lItr) {
        complement.insert(*rItr);
        rItr++;
      } else {
        complement.insert(*lItr);
        lItr++;
        rItr++;
      }
    }
  }
}

#endif
