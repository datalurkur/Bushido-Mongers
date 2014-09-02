#include "curseme/curselog.h"
#include "util/log.h"
#include <string>
#include <math.h>

CursesLogWindow::CursesLogWindow(Window* window): _window(window), _historyLength(1024) {
  Log::RegisterListener(this);
  _window->setBox();
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
  const IVec2& dims = _window->getDims();

  int adjustedWidth = dims.x - 2;

  auto itr = _logs.rbegin();

  int row = dims.y - 2;
  while(itr != _logs.rend() && row > 0) {
    string nextLog = *itr++;
    if((int)nextLog.size() < dims.x) {
      printLine(row--, adjustedWidth, nextLog.c_str());
    } else {
      int leftover = nextLog.size() % dims.x;
      int lines = nextLog.size() / dims.x;
      printLine(row--, adjustedWidth, nextLog.substr(lines * adjustedWidth, leftover).c_str());
      for(int i = lines - 1; i > 0 && row > 0; i--) {
        printLine(row--, adjustedWidth, nextLog.substr(i * adjustedWidth, adjustedWidth).c_str());
      }
    }
  }

  _window->refresh();
}

void CursesLogWindow::printLine(int row, int width, const string& line) {
  string toPrint = line + string(width - line.size(), ' ');
  _window->printText(1, row, toPrint.c_str());
}
