#include "curseme/hotkeymenudriver.h"

HotkeyMenuDriver::HotkeyMenuDriver(const string& title, Window* parent): MenuDriver(title, parent) {}

HotkeyMenuDriver::~HotkeyMenuDriver() {}

size_t HotkeyMenuDriver::numChoices() const {
  return _choices.size();
}

void HotkeyMenuDriver::redraw(const vector<string>& choices) {
  _choices = choices;
  assignHotkeys();
  onSelectionUpdate();
}

void HotkeyMenuDriver::previousPage() { ASSERT(0, "NOT IMPLEMENTED"); }
void HotkeyMenuDriver::nextPage() { ASSERT(0, "NOT IMPLEMENTED"); }

bool HotkeyMenuDriver::makeHotkeySelection(int c, size_t& index) {
  auto itr = _hotkeys.find(c);
  if(itr == _hotkeys.end()) {
    return false;
  } else {
    index = itr->second;
    return true;
  }
}

void HotkeyMenuDriver::onSelectionUpdate() {
  Window* win = _container->usableArea();
  win->clear();

  string blankCursor(Cursor.size(), ' ');
  if(_choices.size() > 0) {
    for(size_t i = 0; i < _choices.size(); i++) {
      string lineText(" " + ((i == _index) ? Cursor : blankCursor) + " " + _choices[i]);
      win->printText(0, i, lineText.c_str());
      win->printChar(lineText.size() + 1, i, '(');
      win->printFormattedChar(lineText.size() + 2, i, _hotkeys.reverseFind(i)->second, COLOR_PAIR(GREEN_ON_BLACK));
      win->printChar(lineText.size() + 3, i, ')');
    }
  } else {
    win->printText(1, 0, "-no selection-");
  }

  win->refresh();
}

void HotkeyMenuDriver::assignHotkeys() {
  _hotkeys.clear();
  for(size_t i = 0; i < _choices.size(); i++) {
    const string& c = _choices[i];

    bool assigned = false;
    for(size_t j = 0; j < c.size(); j++) {
      char hotkey = tolower(c[j]);
      if(_hotkeys.find(hotkey) == _hotkeys.end()) {
        //Info("Assigning hotkey " << hotkey << " to " << c);
        _hotkeys.insert(hotkey, i);
        assigned = true;
        break;
      }
    }

    if(assigned) { continue; }

    for(char a = 'a'; a <= 'z'; a++) {
      if(_hotkeys.find(a) == _hotkeys.end()) {
        //Info("Assigning hotkey " << a << " to " << c);
        _hotkeys.insert(a, i);
        assigned = true;
        break;
      }
    }

    ASSERT(assigned, "Unable to assign a hotkey to choice, likely there is a menu that has grown quite large");
  }
}
