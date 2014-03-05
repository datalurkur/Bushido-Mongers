#include <time.h>

class Timer {
public:
  Timer();

  void start();
  void stop();
  void resume();
  void report();

private:
  clock_t _start;
  clock_t _accum;
};
