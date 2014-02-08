#include "filesystem.h"
#include "stringhelper.h"

#include <list>

unsigned int FileSystem::GetFileData(const string& filename, char **data) {
  FILE *file;
  unsigned int size;

#if SYS_PLATFORM == PLATFORM_WIN32
  // For some reason, fopen is considered "unsafe" on Win32
  // Did I mention I really hate Windows development?
  fopen_s(&file, filename.c_str(), "r");
#else
  file = fopen(filename.c_str(), "r");
#endif
  // Determine the filesize
  fseek(file, 0, SEEK_END);
  size = (unsigned int)ftell(file);
  rewind(file);

  if(!file) { return 0; }
  
  (*data) = (char*)calloc(size, sizeof(char));
  fread(*data, sizeof(char), size, file);
  
  fclose(file);
  
  return size;
}

bool FileSystem::SaveFileData(const string& filename, char* data, unsigned int size) {
  FILE *file;

#if SYS_PLATFORM == PLATFORM_WIN32
  fopen_s(&file, filename.c_str(), "w");
#else
  file = fopen(filename.c_str(), "w");
#endif
  if(!file) { return false; }
  
  fwrite(data, sizeof(char), size, file);
  
  return true;
}

void FileSystem::CleanFilename(const string& filename, string& cleaned) {
  int i, j;

  string itermediate = filename;

  // Replace backslashes with forward slashes
  i = 0;
  while(i < (int)itermediate.size()) {
    j = (int)itermediate.find('\\', i);
    if(j != -1) {
      itermediate[j] = '/';
      i = j+1;
    } else {
      break;
    }
  }
  
  // Find double-dots and deal with them
  list<string> pieces;
  TokenizeString(itermediate, "/", pieces);
  
  list<string>::reverse_iterator ritr;
  cleaned = "";
  for(ritr = pieces.rbegin(); ritr != pieces.rend(); ritr++) {
    i = 0;
    while((*ritr) == "..") {
      ritr++;
      i++;
      if(ritr == pieces.rend()) { return; }
    }
    while(i > 0) {
      ritr++;
      i--;
      if(ritr == pieces.rend()) { return; }
    }
    cleaned = (*ritr) + "/" + cleaned;
  }
}
