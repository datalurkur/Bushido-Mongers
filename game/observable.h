#ifndef OBSERVABLE_H
#define OBSERVABLE_H

#include "util/timestamp.h"

class Observable {
public:
  Observable();

  time_t lastChanged() const;
  void setLastChanged(time_t changed);

protected:
  void markChanged();

private:
  time_t _lastChanged;
};

#endif
