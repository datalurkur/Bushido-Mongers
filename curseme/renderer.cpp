#include "curseme/renderer.h"
#include "util/log.h"
#include "util/filesystem.h"

#include <stdlib.h>
#include <cstring>

using namespace std;

RenderSource::RenderSource(int w, int h): RenderSource(IVec2(w, h)) {}
RenderSource::RenderSource(const IVec2& dims): _dims(dims) {
  size_t size = _dims.x * _dims.y;
  _data       = new chtype[size];
  _attributes = new attr_t[size];
  setData('~', A_NORMAL);
}
RenderSource::~RenderSource() {
  delete _data;
  delete _attributes;
}
void RenderSource::getData(int x, int y, chtype& data, attr_t& attributes) {
  if(!checkBounds(x, y)) { return; }
  data       = _data      [y * _dims.x + x];
  attributes = _attributes[y * _dims.x + x];
}
void RenderSource::setData(int x, int y, chtype data, attr_t attributes) {
  if(!checkBounds(x, y)) { return; }
  size_t index = y * _dims.x + x;
  _data      [index] = data;
  _attributes[index] = attributes;
}
void RenderSource::setAttributes(int x, int y, attr_t attributes) {
  if(!checkBounds(x, y)) { return; }
  _attributes[y * _dims.x + x] = attributes;
}
void RenderSource::setData(chtype data, attr_t attributes) {
  for(int i = 0; i < _dims.x; i++) {
    for(int j = 0; j < _dims.y; j++) {
      setData(i, j, data, attributes);
    }
  }
}
const IVec2& RenderSource::getDimensions() const {
  return _dims;
}

void RenderSource::writeDebug(const string& filename) {
  int size = (_dims.x + 1) * _dims.y;
  chtype* data = (chtype*)calloc(size, sizeof(chtype));
  int index = 0;
  for(int i = 0; i < _dims.y; i++) {
    memcpy((void*)&data[index], (void*)&_data[i * _dims.x], _dims.y);
    index += _dims.y;
    data[index] = '\n';
    index ++;
  }
  if(!FileSystem::SaveFileData(filename, data, size)) {
    Error("Failed to write RenderSource debug data to " << filename);
  }
}

bool RenderSource::checkBounds(int x, int y) {
  if(x < 0 || y < 0 || x >= _dims.x || y >= _dims.y) {
    Error("Coordinates " << x << "," << y << " are outside the bounds of " << _dims);
    return false;
  }
  return true;
}

RenderTarget::RenderTarget(Window* window): _window(window), _source(0), _offset(0, 0) {}
RenderTarget::RenderTarget(Window* window, RenderSource* source): _window(window), _source(source), _offset(0, 0) {}

void RenderTarget::setOffset(const IVec2& offset) {
  _offset = offset;
}

void RenderTarget::setCenter(const IVec2& center) {
  _offset = center - (_window->getDims() / 2);
}

void RenderTarget::nudgeOffset(const IVec2& nudge) {
  _offset += nudge;
}

void RenderTarget::render() {
  const IVec2& wDims = _window->getDims();

  // If there's no render source, clear the window
  string emptyLine(wDims.x, ' ');
  if(!_source) {
    for(int i = 0; i < wDims.y; i++) {
      _window->printText(0, i, emptyLine.c_str());
    }
    return;
  }

  IVec2 sDims = _source->getDimensions();

  // Get the current window attributes and store them off for restoring later
  attr_t originalAttributes;
  short originalColor;
  _window->getAttributes(originalAttributes, originalColor);

  attr_t prevAttrs = originalAttributes;

  string runStart(max(0, -_offset.x), ' ');
  string runEnd(max(0, wDims.x - sDims.x + _offset.x), ' ');

  int xLower = max(0, -_offset.x),
      xUpper = min(wDims.x, sDims.x - _offset.x);

  for(int y = 0; y < wDims.y; y++) {
    if(y < -_offset.y || (y + _offset.y) >= sDims.y) {
      _window->printText(0, y, emptyLine.c_str());
      continue;
    }

    // Group characters together by common attributes as we advance through the buffers
    string run = runStart;

    for(int x = xLower; x < xUpper; x++) {
      chtype data;
      attr_t attributes;
      _source->getData(x + _offset.x, y + _offset.y, data, attributes);

      if(attributes != prevAttrs || data > 255) {
        // Previous character run terminates, begin the new one
        _window->printText(x - run.size(), y, run.c_str());
        run = "";

        if(attributes != prevAttrs) {
          // Set the attributes for the new character run
          prevAttrs = attributes;
          _window->setAttributes(attributes);
        }
        if(data > 255) {
          _window->printChar(x, y, data);
        }
      }

      if(data <= 255) {
        // Append this character to the character run
        run += data;
      }
    }

    // Finish up this row
    _window->printText(wDims.x - runEnd.size() - run.size(), y, run.c_str());
    _window->setAttributes(originalAttributes, originalColor);
    prevAttrs = originalAttributes;
    if(runEnd.size() > 0) {
      _window->printText(wDims.x - runEnd.size(), y, runEnd.c_str());
    }
  }

  // Restore the previous attributes
  _window->setAttributes(originalAttributes, originalColor);
  _window->refresh();
}

void RenderTarget::setRenderSource(RenderSource* source) {
  _source = source;
}

chtype getMarchingSquaresRepresentation(short wallBits) {
  bool bl = wallBits & MARCHING_SQUARES_BIT(-1, -1),
       bc = wallBits & MARCHING_SQUARES_BIT( 0, -1),
       br = wallBits & MARCHING_SQUARES_BIT( 1, -1),
       cl = wallBits & MARCHING_SQUARES_BIT(-1,  0),
       cr = wallBits & MARCHING_SQUARES_BIT( 1,  0),
       ul = wallBits & MARCHING_SQUARES_BIT(-1,  1),
       uc = wallBits & MARCHING_SQUARES_BIT( 0,  1),
       ur = wallBits & MARCHING_SQUARES_BIT( 1,  1);

       if(bc && uc && cr && cl && !((ul || br) && (ur || bl))) { return ACS_PLUS; }
  else if(uc && cl && cr && !((ul || ur) && ((ul && ur) || bc))) { return ACS_TTEE; }
  else if(bc && cl && cr && !((bl || br) && ((bl && br) || uc))) { return ACS_BTEE; }
  else if(bc && uc && cr && !((ur || br) && ((ur && br) || cl))) { return ACS_LTEE; }
  else if(bc && uc && cl && !((ul || bl) && ((ul && bl) || cr))) { return ACS_RTEE; }
  else if(cl && cr && !(uc && bc)) { return ACS_HLINE; }
  else if(bc && uc && !(cl && cr)) { return ACS_VLINE; }
  else if(bc && cr && ((!uc && !cl) || !br)) { return ACS_LLCORNER; }
  else if(bc && cl && ((!cr && !uc) || !bl)) { return ACS_LRCORNER; }
  else if(uc && cl && ((!bc && !cr) || !ul)) { return ACS_URCORNER; }
  else if(uc && cr && ((!bc && !cl) || !ur)) { return ACS_ULCORNER; }
  else if(!(uc || bc || cr) || !(uc || bc || cl) || !(bc || cl || cr) || !(uc || cl || cr)) { return 'O'; }
  else { return ' '; }
}
