#ifndef FILESYSTEM_H
#define FILESYSTEM_H

#include "platform.h"

#include <string>

#if SYS_PLATFORM == PLATFORM_WIN32
# include <io.h>
# include <direct.h>
#else
# include <dirent.h>
#endif

using namespace std;

class FileSystem {
public:
  template <typename T>
  static void GetDirectoryContents(const string& dir, T& files, bool includeDirectories = true);

  static unsigned int GetFileData(const string& filename, void** data);
  static bool SaveFileData(const string& filename, const void* data, unsigned int size);

  static void CleanFilename(const string& filename, string& cleaned);

  static string JoinFilename(const string& dir, const string& file);
};

template <typename T>
void FileSystem::GetDirectoryContents(const string& dir, T& files, bool includeDirectories) {
  string cleanDirName;
  
  // Clean up the directory name
  CleanFilename(dir, cleanDirName);
  
#if SYS_PLATFORM == PLATFORM_WIN32
  _finddata_t fileInfo;
  intptr_t handle;
  
  // Ensure the directory name ends in a wildcard for Win32
  if(cleanDirName[cleanDirName.size()-1] != '/') {
    cleanDirName += '/';
  }
  cleanDirName += "*";
  
  // Iterate through the directory
  if((handle = _findfirst(cleanDirName.c_str(), &fileInfo)) == -1) {
    return;
  }
  while(_findnext(handle, &fileInfo) == 0) {
    if((fileInfo.name[0] != '.') && (fileInfo.attrib != _A_SUBDIR || includeDirectories)) {
      files.push_back(fileInfo.name);
    }
  }
  
  // Cleanup
  _findclose(handle);
#else
  DIR *dirObj;
  dirent *entry;
  
  // Check that the directory exists
  dirObj = opendir(dir.c_str());
  if(dirObj == 0) { return; }
  
  // Iterate through the directory
  while((entry = readdir(dirObj)) != 0) {
    if((entry->d_name[0] != '.') && (entry->d_type == DT_REG || includeDirectories)) {
      files.push_back(entry->d_name);
    }
  }
  
  // Cleanup
  closedir(dirObj);
#endif
}

#endif
