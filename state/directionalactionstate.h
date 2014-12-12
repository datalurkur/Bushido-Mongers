#include "ui/state.h"
#include "io/localbackend.h"

class DirectionalActionState: public UIState {
public:
  enum ActionType {
    Attack
  };

public:
  DirectionalActionState(LocalBackEnd* client, ActionType type);
  virtual ~DirectionalActionState();

protected:
  bool act(int action);

private:
  LocalBackEnd* _client;
  ActionType _type;
};
