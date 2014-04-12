#include "world/tilebase.h"

TileBase::TileBase(TileType type): _type(type) {}

TileBase::~TileBase() {}

void TileBase::setType(TileType type) { _type = type; }

TileType TileBase::getType() const { return _type; }

