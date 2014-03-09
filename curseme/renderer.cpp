#include "curseme/renderer.h"

#include <stdlib.h>
#include <cstring>

using namespace std;

AsciiRenderer::AsciiRenderer(int x, int y, int w, int h):
  _w(w-2), _h(h-2), _outputData(0), _oX(0), _oY(0), _iW(0), _iH(0), _inputData(0) {
  resize(_w, _h);

  _window = newwin(h, w, y, x);
  box(_window, 0, 0);
}

AsciiRenderer::~AsciiRenderer() {
  delwin(_window);

  clearOutput();
  clearInput();
}

void AsciiRenderer::setInputData(const char** source, int w, int h) {
  clearInput();

  _iW = w;
  _iH = h;

  _inputData = (char**)calloc(sizeof(char*), h);
  for(int i = 0; i < h; i++) {
    _inputData[i] = (char*)calloc(sizeof(char), w);
    memcpy(_inputData[i], source[i], sizeof(char) * w);
  }

  computeOutput();
}

void AsciiRenderer::setInputData(const char* source, int w, int h) {
  clearInput();
  _iW = w;
  _iH = h;

  _inputData = (char**)calloc(sizeof(char*), h);
  for(int i = 0; i < h; i++) {
    _inputData[i] = (char*)calloc(sizeof(char), w);
    memcpy(_inputData[i], &source[i*w], sizeof(char) * w);
  }

  computeOutput();
}

void AsciiRenderer::render() {
  for(int i = 0; i < _h; i++) {
    mvwprintw(_window, i+1, 1, _outputData[i]);
  }
  wrefresh(_window);
}

void AsciiRenderer::clearOutput() {
  if(_outputData) {
    for(int i = 0; i < _h; i++) {
      free(_outputData[i]);
    }
    free(_outputData);
    _outputData = 0;
  }
}

void AsciiRenderer::clearInput() {
  if(_inputData) {
    for(int i = 0; i < _iH; i++) {
      free(_inputData[i]);
    }
    free(_inputData);
    _inputData = 0;
  }
}

void AsciiRenderer::resize(int w, int h) {
  clearOutput();

  _w = w;
  _h = h;

  _outputData = (char**)calloc(sizeof(char*), _h);
  for(int i = 0; i < _h; i++) {
    _outputData[i] = (char*)calloc(sizeof(char), _w);
  }

  computeOutput();
}

void AsciiRenderer::computeOutput() {
  if(_inputData) {
    for(int i = 0; i < _h && (i + _oY) < _iH; i++) {
      for(int j = 0; j < _w && (j + _oX) < _iW; j++) {
        _outputData[i][j] = _inputData[i + _oX][j + _oY];
      }
    }
  }
}
