#ifndef OBJECT_EXTENSION_H
#define OBJECT_EXTENSION_H

struct GameEvent;

class BObjectExtension {
public:
  BObjectExtension();
  virtual ~BObjectExtension();

  virtual void react(GameEvent* event) = 0;
  virtual void update() = 0;

private:
};

#endif
