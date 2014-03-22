#ifndef TIMESTAMP_H
#define TIMESTAMP_H

#include <time.h>

extern time_t GetTimestamp();
extern clock_t GetClock();
extern double ClocksToSeconds(clock_t clocks);

#endif
