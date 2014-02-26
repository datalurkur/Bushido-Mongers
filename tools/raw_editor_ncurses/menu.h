#ifndef MENU_H
#define MENU_H

#include <string>
#include <sstream>

using namespace std;

template <size_t N>
void do_menu_no_desc(std::array<const char *, N> choices);

template <size_t N>
void do_menu(std::array<const char *, N> choices, std::array<const char *, N> descriptions);

#endif
