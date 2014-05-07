#ifndef STRUCTURE_H
#define STRUCTURE_H

#include <set>

using namespace std;

template <typename T>
set<T>&& operator-(const set<T>& lhs, const set<T>& rhs) {
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

#endif
