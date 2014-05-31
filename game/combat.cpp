#include "game/combat.h"

Damage::Damage(const Damage& other):
  type(other.type), amount(other.amount), source(other.source) {}
