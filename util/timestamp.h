#ifndef TIMESTAMP_H
#define TIMESTAMP_H

# include <time.h>
# include <sys/time.h>

#ifdef __MACH__
# include <mach/clock.h>
# include <mach/mach.h>
typedef mach_timespec_t PreciseClock;
#else
typedef timespec PreciseClock;
#endif

class ClockInterface {
public:
  ClockInterface();
  ~ClockInterface();

  time_t getTime();
  clock_t getClock();
  PreciseClock getMonotonicClock();

  double getElapsedSeconds(const PreciseClock& start);
  double getElapsedSeconds(const PreciseClock& start, const PreciseClock& end);

private:
#ifdef __MACH__
  clock_serv_t _clockServ;
#endif
};

extern ClockInterface Clock;

#endif
