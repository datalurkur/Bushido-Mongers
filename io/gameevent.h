#ifndef GAMEEVENT_H
#define GAMEEVENT_H

enum GameEventType {
  CreateCharacter
};

struct GameEvent {
  GameEventType type;

  GameEvent(GameEventType t): type(t) {}
};

struct CreateCharacterEvent: public GameEvent {
  CreateCharacterEvent(): GameEvent(GameEventType::CreateCharacter) {}
};

#endif
