#ifndef TIMED_MAP_H
#define TIMED_MAP_H

#include "util/timestamp.h"

#include <queue>
#include <map>
using namespace std;

template <typename T>
class TimedMap {
public:
  TimedMap(time_t timeout);

  time_t get(const T& k);
  bool has(const T& k);
  void set(const T& k, time_t last);
  void set(const T& k);

  void cleanup();
  void clear();

private:
  time_t _timeout;
  map<T, time_t> _timestamps;
  queue<T> _insertions;
};

template <typename T>
TimedMap<T>::TimedMap(time_t timeout): _timeout(timeout) {}

template <typename T>
time_t TimedMap<T>::get(const T& k) {
  return _timestamps[k];
}

template <typename T>
bool TimedMap<T>::has(const T& k) {
  auto itr = _timestamps.find(k);
  if(itr != _timestamps.end()) { return true; }
  else { return false; }
}

template <typename T>
void TimedMap<T>::set(const T& k, time_t last) {
  _timestamps[k] = last;
  _insertions.push(k);
}

template <typename T>
void TimedMap<T>::set(const T& k) {
  set(k, Clock.getTime());
}

template <typename T>
void TimedMap<T>::cleanup() {
  time_t threshold = Clock.getTime() - _timeout;
  while(!_insertions.empty()) {
    T key = _insertions.front();
    auto itr = _timestamps.find(key);
    if(itr == _timestamps.end()) {
      _insertions.pop();
    } else if(itr.second < threshold) {
      _timestamps.erase(itr);
      _insertions.pop();
    } else {
      break;
    }
  }
}

template <typename T>
void TimedMap<T>::clear() {
  _timestamps.clear();

  // Apparently std::queue doesn't support clear?  So we do this fuckery instead
  queue<T>().swap(_insertions);
}

#endif
