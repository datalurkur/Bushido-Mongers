#ifndef WINDOW_H
#define WINDOW_H

#include "curseme/curseme.h"
#include "util/vector.h"

#include <string>
#include <sstream>

using namespace std;

class Window {
public:
  enum Alignment {
    TOP_LEFT,
    TOP_CENTER,
    TOP_RIGHT,
    CENTER,
    CENTER_LEFT,
    CENTER_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_CENTER,
    BOTTOM_RIGHT
  };

public:
  Window(int w, int h, int x, int y, Window* parent = 0);
  Window(Alignment anchor, float wRatio, float hRatio, int wPad, int hPad, int xPad, int yPad, Window* parent = 0);
  Window(Alignment anchor, int w, int h, int xPad, int yPad, Window* parent = 0);
  ~Window();

  const IVec2& getDims() const;

  void refresh();
  void clear();

  void setBox();
  void setAsMenuWindow(MENU* menu);
  void setAsMenuSubwindow(MENU* menu);
  void setCursorPosition(int x, int y);

  void printText(int x, int y, const char* fmt, ...);
  void printChar(int x, int y, const chtype c);
  void printFormattedChar(int x, int y, const chtype c, attr_t attributes);
  void printHRule(int x, int y, chtype c, int n);

  int getChar();
  int getString(string& str);

  void getAttributes(attr_t& attributes, short& color);
  void setAttributes(attr_t attributes);
  void setAttributes(attr_t attributes, short color);

protected:
  WINDOW* createSubWindow(int w, int h, int dX, int dY);

private:
  void determineMaxDimensions(int& mW, int& mH);
  void determineCoordinates(Alignment anchor, int mW, int mH, int xPad, int yPad, int w, int h, int& x, int& y);
  void setupWindow(int w, int h, int x, int y);

protected:
  Window* _parent;
  WINDOW* _win;
  IVec2 _dims;
};

#endif
