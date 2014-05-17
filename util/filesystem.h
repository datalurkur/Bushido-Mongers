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

  template <typename T>
  static void GetDirectoryContentsRecursive(const string& dir, T& files);

  static unsigned int GetFileData(const string& filename, void** data);
  static bool SaveFileData(const string& filename, const void* data, unsigned int size);

  static void CleanFilename(const string& filename, string& cleaned);

  static string JoinFilename(const string& dir, const string& file);

  static string TrimExtension(const string& filename);
  static string TrimPath(const string& filename);
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

template <typename T>
void FileSystem::GetDirectoryContentsRecursive(const string& root, T& files) {
  T dirs;
  dirs.push_back(root);

  string cleanDirName;
  
  typename T::iterator itr = dirs.begin();

  while(itr != dirs.end()) {
    // Clean up the directory name
    CleanFilename(*itr, cleanDirName);
  
#if SYS_PLATFORM == PLATFORM_WIN32
    _finddata_t fileInfo;
    intptr_t handle;
    
    // Ensure the directory name ends in a wildcard for Win32
    if(cleanDirName[cleanDirName.size()-1] != '/') {
      cleanDirName += '/';
    }

    string searchName = cleanDirName + "*";
    
    // Iterate through the directory
    if((handle = _findfirst(searchName.c_str(), &fileInfo)) == -1) {
      return;
    }
    while(_findnext(handle, &fileInfo) == 0) {
      if(fileInfo.name[0] != '.') {
        string fullName = cleanDirName + fileInfo.name;
        (fileInfo.attrib == _A_SUBDIR) ? dirs.push_back(fullName) : files.push_back(fullName);
      }
    }
    
    // Cleanup
    _findclose(handle);
#else
    DIR *dirObj;
    dirent *entry;
    
    // Check that the directory exists
    dirObj = opendir(cleanDirName.c_str());
    if(dirObj == 0) { return; }
    
    // Iterate through the directory
    while((entry = readdir(dirObj)) != 0) {
      if(entry->d_name[0] != '.') {
        string fullName = cleanDirName + entry->d_name;
        (entry->d_type == DT_REG) ? files.push_back(fullName) : dirs.push_back(fullName);
      }
    }
    
    // Cleanup
    closedir(dirObj);
#endif

    itr++;
  }
}

#endif
