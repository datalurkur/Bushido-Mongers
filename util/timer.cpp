#include "util/timer.h"
#include "util/log.h"

Timer::Timer() {}

void Timer::start() {
  _accum = 0;
  resume();
}

void Timer::stop() {
  clock_t stop = clock();
  _accum += stop - _start;
}

void Timer::resume() {
  _start = clock();
}

void Timer::report() {
  Info("Total execution time: " << (float)_accum / CLOCKS_PER_SEC << " seconds");
}
