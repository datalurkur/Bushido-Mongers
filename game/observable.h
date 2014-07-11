#ifndef OBSERVABLE_H
#define OBSERVABLE_H

#include "util/timestamp.h"

class Observable {
public:
  Observable();

  time_t lastChanged() const;
  void setLastChanged(time_t changed);

  // An attachment point for subclasses to define custom behavior when they're observed
  virtual void onChanged();

protected:
  void markChanged();

private:
  time_t _lastChanged;
};

#endif
