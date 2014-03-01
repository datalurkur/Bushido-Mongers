#include "util/log.h"
#include "util/filesystem.h"

#include "game/bobjectmanager.h"

int main() {
  Log::Setup();
  Info("Logging set up");

  BObjectManager* manager = new BObjectManager("raws");
  BObject* meatwad = manager->createObject("torso");
  if(!meatwad) {
    Error("Sadly, failed to create meatwad");
  } else {
    Info("Meatwad exists!  He weighs " << meatwad->getWeight() << " pounds!");
  }

  delete manager;

  Log::Teardown();
  return 0;
}
