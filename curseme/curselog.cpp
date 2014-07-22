#include "curseme/curselog.h"
#include "util/log.h"
#include <string>
#include <math.h>

CursesLogWindow::CursesLogWindow(WINDOW* window): _window(window), _historyLength(1024) {
  Log::RegisterListener(this);
  box(_window, 0, 0);
  wrefresh(_window);
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

  int adjustedWidth = w - 2;

  auto itr = _logs.rbegin();

  int row = h - 2;
  while(itr != _logs.rend() && row > 0) {
    string nextLog = *itr++;
    if((int)nextLog.size() < w) {
      printLine(row--, adjustedWidth, nextLog.c_str());
    } else {
      int leftover = nextLog.size() % w;
      int lines = nextLog.size() / w;
      printLine(row--, adjustedWidth, nextLog.substr(lines * adjustedWidth, leftover).c_str());
      for(int i = lines - 1; i > 0 && row > 0; i--) {
        printLine(row--, adjustedWidth, nextLog.substr(i * adjustedWidth, adjustedWidth).c_str());
      }
    }
  }

  wrefresh(_window);
}

void CursesLogWindow::printLine(int row, int width, const string& line) {
  BeginCursesOperation;
  string toPrint = line + string(width - line.size(), ' ');
  mvwprintw(_window, row, 1, toPrint.c_str());
}
