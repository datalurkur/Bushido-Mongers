#ifndef BIMAP_H
#define BIMAP_H

#include <map>

using namespace std;

template <typename T, typename S>
class BiMap {
public:
  BiMap();
  ~BiMap();

  S& lookup(const T& key);
  T& reverseLookup(const S& key);

  typename map<T, S>::iterator find(const T& key);
  typename map<S, T>::iterator reverseFind(const S& value);

  typename map<T, S>::iterator begin();
  typename map<S, T>::iterator reverseBegin();
  typename map<T, S>::iterator end();
  typename map<S, T>::iterator reverseEnd();

  void insert(const T& key, const S& value);

  void erase(const T& key);
  void erase(typename map<T,S>::iterator itr);
  void reverseErase(const S& value);
  void reverseErase(typename map<S,T>::iterator itr);

private:
  map<T, S> _forwardMap;
  map<S, T> _backwardMap;
};

template <typename T, typename S>
BiMap<T,S>::BiMap() {}

template <typename T, typename S>
BiMap<T,S>::~BiMap() {}

template <typename T, typename S>
S& BiMap<T,S>::lookup(const T& key) {
  return _forwardMap[key];
}

template <typename T, typename S>
T& BiMap<T,S>::reverseLookup(const S& key) {
  return _backwardMap[key];
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
typename map<T, S>::iterator BiMap<T,S>::find(const T& key) {
  return _forwardMap.find(key);
}

template <typename T, typename S>
typename map<S, T>::iterator BiMap<T,S>::reverseFind(const S& value) {
  return _backwardMap.find(value);
}

template <typename T, typename S>
typename map<T, S>::iterator BiMap<T,S>::begin() { return _forwardMap.begin(); }

template <typename T, typename S>
typename map<S, T>::iterator BiMap<T,S>::reverseBegin() { return _backwardMap.begin(); }

template <typename T, typename S>
typename map<T, S>::iterator BiMap<T,S>::end() { return _forwardMap.end(); }

template <typename T, typename S>
typename map<S, T>::iterator BiMap<T,S>::reverseEnd() { return _backwardMap.end(); }

template <typename T, typename S>
void BiMap<T,S>::erase(const T& key) {
  auto fItr = _forwardMap.find(key);
  if(fItr != _forwardMap.end()) { erase(fItr); }
}

template <typename T, typename S>
void BiMap<T,S>::erase(typename map<T,S>::iterator itr) {
  _backwardMap.erase(itr->second);
  _forwardMap.erase(itr);
}

template <typename T, typename S>
void BiMap<T,S>::reverseErase(const S& value) {
  auto bItr = _backwardMap.find(value);
  if(bItr != _backwardMap.end()) { reverseErase(bItr); }
}

template <typename T, typename S>
void BiMap<T,S>::reverseErase(typename map<S,T>::iterator itr) {
  _forwardMap.erase(itr->second);
  _backwardMap.erase(itr);
}

#endif
