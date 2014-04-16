#ifndef TIMED_MAP_H
#define TIMED_MAP_H

#include "util/timestamp.h"

template <typename T>
class TimedMap {
public:
  TimedMap(time_t timeout);

  time_t get(const T& k);
  bool has(const T& k);
  void set(const T& k, time_t last);

  void cleanup();

private:
  time_t _timeout;
  map<T, time_t> _timestamps;
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
}

template <typename T>
void TimedMap<T>::cleanup() {
  time_t newTime = Clock.getTime() + _timeout;
  for(auto itr = _timestamps.begin(); itr != _timestamps.end();) {
    if(itr.second < newTime) { _timestamps.erase(itr++); }
    else { ++itr; }
  }
}

#endif
