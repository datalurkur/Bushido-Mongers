#include "util/timestamp.h"

time_t GetTimestamp() {
  return time(NULL);
}

clock_t GetClock() {
  return clock();
}

double ClocksToSeconds(clock_t clocks) {
  return static_cast<double>(clocks / CLOCKS_PER_SEC);
}
