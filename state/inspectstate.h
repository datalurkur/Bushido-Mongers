#include "ui/state.h"
#include "io/localbackend.h"

class InspectState: public UIState {
public:
  InspectState(LocalBackEnd* client);
  virtual ~InspectState();

protected:
  bool act(int action);

private:
  LocalBackEnd* _client;
};
