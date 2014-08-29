#ifndef BIMAP_H
#define BIMAP_H

#include <map>

using namespace std;

template <typename T, typename S>
class BiMap {
public:
  BiMap();
  ~BiMap();

  const S& lookup(const T& key) const;
  const T& reverseLookup(const S& key) const;

  typename map<T, S>::const_iterator find(const T& key) const;
  typename map<S, T>::const_iterator reverseFind(const S& value) const;

  typename map<T, S>::const_iterator begin() const;
  typename map<S, T>::const_iterator reverseBegin() const;
  typename map<T, S>::const_iterator end() const;
  typename map<S, T>::const_iterator reverseEnd() const;

  void insert(const T& key, const S& value);

  void erase(const T& key);
  void erase(typename map<T,S>::const_iterator itr);
  void reverseErase(const S& value);
  void reverseErase(typename map<S,T>::const_iterator itr);

  void clear();

private:
  map<T, S> _forwardMap;
  map<S, T> _backwardMap;
};

template <typename T, typename S>
BiMap<T,S>::BiMap() {}

template <typename T, typename S>
BiMap<T,S>::~BiMap() {}

template <typename T, typename S>
const S& BiMap<T,S>::lookup(const T& key) const {
  auto itr = find(key);
  ASSERT(itr != _forwardMap.end(), "Key not found in forward map");
  return itr->second;
}

template <typename T, typename S>
const T& BiMap<T,S>::reverseLookup(const S& key) const {
  auto itr = reverseFind(key);
  ASSERT(itr != _backwardMap.end(), "Value not found in reverse map");
  return itr->second;
}

template <typename T, typename S>
void BiMap<T,S>::insert(const T& key, const S& value) {
  // Toast the reverse lookups if they exist
  auto fItr = _forwardMap.find(key);
  if(fItr != _forwardMap.end()) { _backwardMap.erase(fItr->second); }
  auto bItr = _backwardMap.find(value);
  if(bItr != _backwardMap.end()) { _forwardMap.erase(bItr->second); }

  // Assign the new values
  _forwardMap[key] = value;
  _backwardMap[value] = key;
}

template <typename T, typename S>
typename map<T, S>::const_iterator BiMap<T,S>::find(const T& key) const {
  return _forwardMap.find(key);
}

template <typename T, typename S>
typename map<S, T>::const_iterator BiMap<T,S>::reverseFind(const S& value) const {
  return _backwardMap.find(value);
}

template <typename T, typename S>
typename map<T, S>::const_iterator BiMap<T,S>::begin() const { return _forwardMap.begin(); }

template <typename T, typename S>
typename map<S, T>::const_iterator BiMap<T,S>::reverseBegin() const { return _backwardMap.begin(); }

template <typename T, typename S>
typename map<T, S>::const_iterator BiMap<T,S>::end() const { return _forwardMap.end(); }

template <typename T, typename S>
typename map<S, T>::const_iterator BiMap<T,S>::reverseEnd() const { return _backwardMap.end(); }

template <typename T, typename S>
void BiMap<T,S>::erase(const T& key) {
  auto fItr = _forwardMap.find(key);
  if(fItr != _forwardMap.end()) { erase(fItr); }
}

template <typename T, typename S>
void BiMap<T,S>::erase(typename map<T,S>::const_iterator itr) {
  _backwardMap.erase(itr->second);
  _forwardMap.erase(itr);
}

template <typename T, typename S>
void BiMap<T,S>::reverseErase(const S& value) {
  auto bItr = _backwardMap.find(value);
  if(bItr != _backwardMap.end()) { reverseErase(bItr); }
}

template <typename T, typename S>
void BiMap<T,S>::reverseErase(typename map<S,T>::const_iterator itr) {
  _forwardMap.erase(itr->second);
  _backwardMap.erase(itr);
}

template <typename T, typename S>
void BiMap<T,S>::clear() {
  _forwardMap.clear();
  _backwardMap.clear();
}

#endif
