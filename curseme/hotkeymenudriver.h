#ifndef HOTKEY_MENU_DRIVER_H
#define HOTKEY_MENU_DRIVER_H

#include "curseme/menudriver.h"
#include "util/bimap.h"

class HotkeyMenuDriver: public MenuDriver {
public:
  HotkeyMenuDriver(const string& title, const vector<string>& choices, Window* parent = 0);
  ~HotkeyMenuDriver();

  void previousPage();
  void nextPage();

  bool makeHotkeySelection(int c, size_t& index);

protected:
  void onSelectionUpdate();

  void assignHotkeys();

private:
  vector<string> _choices;
  BiMap<char, size_t> _hotkeys;
};

#endif
