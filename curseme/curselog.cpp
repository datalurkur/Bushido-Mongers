#include "curseme/curselog.h"
#include "util/log.h"
#include <string>
#include <math.h>

CursesLogWindow::CursesLogWindow(WINDOW* window): _window(window), _historyLength(1024) {
  Log::RegisterListener(this);
}

CursesLogWindow::~CursesLogWindow() {
  Log::UnregisterListener(this);
}

void CursesLogWindow::logMessage(LogChannel channel, const string& message) {
  _logs.push_back(message);
  if((int)_logs.size() > _historyLength) {
    _logs.pop_front();
  }
  update();
}

void CursesLogWindow::update() {
  int w, h;
  getmaxyx(_window, h, w);

  auto itr = _logs.rbegin();

  int row = h;
  while(itr != _logs.rend() && row > 0) {
    string nextLog = *itr++;
    if((int)nextLog.size() < w) {
      printLine(row--, w, nextLog.c_str());
    } else {
      int leftover = nextLog.size() % w;
      int lines = nextLog.size() / w;
      printLine(row--, w, nextLog.substr(lines * w, leftover).c_str());
      for(int i = lines - 1; i >= 0 && row > 0; i--) {
        printLine(row--, w, nextLog.substr(i * w, w).c_str());
      }
    }
  }

  wrefresh(_window);
}

void CursesLogWindow::printLine(int row, int width, const string& line) {
  string toPrint = line + string(width - line.size(), ' ');
  mvwprintw(_window, row, 1, toPrint.c_str());
}
