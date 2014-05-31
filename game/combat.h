#ifndef COMBAT_H
#define COMBAT_H

#include "game/bobjecttypes.h"

enum DamageType {
  Blunt,
  Piercing,
  Slashing
};

struct DamageResult {
  float absorbed;
  float remaining;
  bool destroyed;
};

struct Damage {
  DamageType type;
  float amount;
  BObjectID source;

  Damage(const Damage& other);
};

// The idea behind Attack is that we can take the characteristics of the variables involved and them compute damage from them
struct Attack {
  float accuracy;
  float swiftness;
  float force;
  BObjectID weapon;
};

#endif
