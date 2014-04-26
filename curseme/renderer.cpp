#include "curseme/renderer.h"
#include "util/log.h"

#include <stdlib.h>
#include <cstring>

using namespace std;

RenderSource::RenderSource(int w, int h): RenderSource(IVec2(w, h)) {}
RenderSource::RenderSource(const IVec2& dims): _dims(dims) {
  size_t size = _dims.x * _dims.y;
  _data       = new char  [size];
  _attributes = new attr_t[size];
  setData('.', A_NORMAL);
}
RenderSource::~RenderSource() {
  delete _data;
  delete _attributes;
}
void RenderSource::getData(int x, int y, char& data, attr_t& attributes) {
  if(!checkBounds(x, y)) { return; }
  data       = _data      [y * _dims.x + x];
  attributes = _attributes[y * _dims.x + x];
}
void RenderSource::setData(int x, int y, char data, attr_t attributes) {
  if(!checkBounds(x, y)) { return; }
  _data      [y * _dims.x + x] = data;
  _attributes[y * _dims.x + x] = attributes;
}
void RenderSource::setAttributes(int x, int y, attr_t attributes) {
  if(!checkBounds(x, y)) { return; }
  _attributes[y * _dims.x + x] = attributes;
}
void RenderSource::setData(char data, attr_t attributes) {
  for(int i = 0; i < _dims.x; i++) {
    for(int j = 0; j < _dims.y; j++) {
      setData(i, j, data, attributes);
    }
  }
}
const IVec2& RenderSource::getDimensions() const {
  return _dims;
}

bool RenderSource::checkBounds(int x, int y) {
  if(x < 0 || y < 0 || x >= _dims.x || y >= _dims.y) {
    Error("Coordinates " << x << "," << y << " are outside the bounds of " << _dims);
    return false;
  }
  return true;
}

RenderTarget::RenderTarget(WINDOW* window): _window(window), _source(0), _offset(0, 0) {}
RenderTarget::RenderTarget(WINDOW* window, RenderSource* source): _window(window), _source(source), _offset(0, 0) {}

void RenderTarget::setOffset(const IVec2& offset) {
  _offset = offset;
}

void RenderTarget::nudgeOffset(const IVec2& nudge) {
  _offset += nudge;
}

void RenderTarget::render() {
  int tW, tH;
  getmaxyx(_window, tH, tW);

  // If there's no render source, clear the window
  string emptyLine(tW, ' ');
  if(!_source) {
    for(int i = 0; i < tH; i++) {
      mvwprintw(_window, i+1, 1, emptyLine.c_str());
    }
    return;
  }

  IVec2 sDims = _source->getDimensions();

  // Get the current window attributes and store them off for restoring later
  void* unused = 0;
  attr_t originalAttributes;
  short originalColor;
  wattr_get(_window, &originalAttributes, &originalColor, unused);
  attr_t prevAttrs = originalAttributes;

  string runStart(max(0, -_offset.x), ' ');
  string runEnd(max(0, tW - sDims.x + _offset.x), ' ');

  int xLower = max(0, -_offset.x),
      xUpper = min(tW, sDims.x - _offset.x);

  for(int y = 0; y < tH; y++) {
    if(y < -_offset.y || (y + _offset.y) >= sDims.y) {
      mvwprintw(_window, y+1, 1, emptyLine.c_str());
      continue;
    }

    // Group characters together by common attributes as we advance through the buffers
    string run = runStart;

    for(int x = xLower; x < xUpper; x++) {
      char data;
      attr_t attributes;
      _source->getData(x + _offset.x, y + _offset.y, data, attributes);

      if(attributes != prevAttrs) {
        // Previous character run terminates, begin the new one
        mvwprintw(_window, y+1, x - run.size() + 1, run.c_str());
        run = "";

        // Set the attributes for the new character run
        prevAttrs = attributes;
        wattrset(_window, attributes);
      }

      // Append this character to the character run
      run += data;
    }

    // Finish up this row
    mvwprintw(_window, y+1, tW - runEnd.size() - run.size() + 1, run.c_str());
    wattr_set(_window, originalAttributes, originalColor, unused);
    prevAttrs = originalAttributes;
    if(runEnd.size() > 0) {
      mvwprintw(_window, y+1, tW - runEnd.size() + 1, runEnd.c_str());
    }
  }

  // Restore the previous attributes
  wattr_set(_window, originalAttributes, originalColor, unused);
  wrefresh(_window);
}

void RenderTarget::setRenderSource(RenderSource* source) {
  _source = source;
}
