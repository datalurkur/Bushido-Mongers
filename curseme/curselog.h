#ifndef CURSELOG_H
#define CURSELOG_H

#include "util/log.h"
#include "curseme/window.h"
#include <list>
#include <string>

using namespace std;

class CursesLogWindow: public LogListener {
public:
  CursesLogWindow(Window* window);
  virtual ~CursesLogWindow();

  void logMessage(LogChannel channel, const string& message);
  void update();

private:
  void printLine(int row, int width, const string& line);

private:
  Window* _window;

  list<string> _logs;
  int _historyLength;
};

#endif
