#ifndef RENDERER_H
#define RENDERER_H

#include "curseme/curseme.h"

class AsciiRenderer {
public:
  AsciiRenderer(int x, int y, int w, int h);
  ~AsciiRenderer();

  void setInputData(const char** source, int w, int h);
  void setInputData(const char* source, int w, int h);

  void render();

  int getInputX() const;
  int getInputY() const;

  void setInputX(int oX);
  void setInputY(int oY);

  WINDOW* getWindow();

private:
  void clearOutput();
  void clearInput();
  void resize(int w, int h);
  void computeOutput();

private:
  int _w, _h;
  char** _outputData;
  int _oX, _oY, _iW, _iH;
  char** _inputData;

  WINDOW* _window;
};

#endif