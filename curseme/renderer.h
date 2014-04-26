#ifndef RENDERER_H
#define RENDERER_H

#include "util/vector.h"
#include "curseme/curseme.h"

class RenderSource {
public:
  RenderSource(int w, int h);
  RenderSource(const IVec2& dims);
  ~RenderSource();

  void getData(int x, int y, char& data, attr_t& attributes);
  void setData(int x, int y, char data, attr_t attributes);
  void setAttributes(int x, int y, attr_t attributes);

  void setData(char data, attr_t attributes);

  const IVec2& getDimensions() const;

private:
  bool checkBounds(int x, int y);

private:
  char* _data;
  attr_t* _attributes;
  IVec2 _dims;
};

class RenderTarget {
public:
  RenderTarget(WINDOW* window);
  RenderTarget(WINDOW* window, RenderSource* source);

  void setOffset(const IVec2& offset);
  void nudgeOffset(const IVec2& nudge);

  void setRenderSource(RenderSource* source);

  void render();

private:
  WINDOW* _window;
  RenderSource* _source;
  IVec2 _offset;
};

#endif
