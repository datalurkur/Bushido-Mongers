#include "util/timestamp.h"

ClockInterface Clock;

ClockInterface::ClockInterface() {
#ifdef __MACH__
  host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &_clockServ);
#endif
}

ClockInterface::~ClockInterface() {
#ifdef __MACH__
  mach_port_deallocate(mach_task_self(), _clockServ);
#endif
}

time_t ClockInterface::getTime() {
  return time(0);
}

clock_t ClockInterface::getClock() {
  return clock();
}

PreciseClock ClockInterface::getMonotonicClock() {
  PreciseClock ret;
#ifdef __MACH__
  clock_get_time(_clockServ, &ret);
#else
  clock_gettime(CLOCK_MONOTONIC, &ret);
#endif
  return ret;
}

double ClockInterface::getElapsedSeconds(const PreciseClock& start) {
  return getElapsedSeconds(start, getMonotonicClock());
}

double ClockInterface::getElapsedSeconds(const PreciseClock& start, const PreciseClock& end) {
  return (double)(end.tv_sec - start.tv_sec) + ((double)(end.tv_nsec - start.tv_nsec) / 1000000000.0);
}
