#ifndef RENDERER_H
#define RENDERER_H

#include "curseme/window.h"

class RenderSource {
public:
  RenderSource(int w, int h);
  RenderSource(const IVec2& dims);
  ~RenderSource();

  void getData(int x, int y, chtype& data, attr_t& attributes);
  void setData(int x, int y, chtype data, attr_t attributes);
  void setAttributes(int x, int y, attr_t attributes);

  void setData(chtype data, attr_t attributes);

  const IVec2& getDimensions() const;

  void writeDebug(const string& filename);

private:
  bool checkBounds(int x, int y);

private:
  chtype* _data;
  attr_t* _attributes;
  IVec2 _dims;
};

class RenderTarget {
public:
  RenderTarget(Window* window);
  RenderTarget(Window* window, RenderSource* source);

  void setOffset(const IVec2& offset);
  void setCenter(const IVec2& center);
  void nudgeOffset(const IVec2& nudge);

  void setRenderSource(RenderSource* source);

  void render();

private:
  Window* _window;
  RenderSource* _source;
  IVec2 _offset;
};

#endif
