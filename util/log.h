#ifndef LOG_H
#define LOG_H

#include <iostream>
#include <fstream>
#include <sstream>

#include "util/config.h"
#include "curseme/curseme.h"

using namespace std;

#define LOG_DEBUG   0x01
#define LOG_INFO    0x02
#define LOG_WARNING 0x04
#define LOG_ERROR   0x08

typedef char LogChannel;

class Log {
public:
  static void EnableAllChannels();
  static void DisableAllChannels();
 
  static void EnableChannel(LogChannel channel);
  static void DisableChannel(LogChannel channel);

  static bool IsChannelEnabled(LogChannel channel);

  static Log& GetLogStream();
  static void Flush();

  static void Setup();
  static void Setup(const string& logfile);
  static void Teardown();

public:
  Log(const string& logfile = "bm.log");
  virtual ~Log();

  static void ToggleStdout();
  static bool stdoutEnabled();

  void flush();

  template <typename T>
  Log& operator<<(const T &rhs);

private:
  static Log *OutputStream;
  static LogChannel ChannelState;
  static bool stdout_flag;

private:
  bool _cleanupStream;
  ostream *_outputStream;
  filebuf *_logFile;
};

template <typename T>
Log& Log::operator<<(const T &rhs) {
  (*_outputStream) << rhs;

  if(stdout_flag) {
    std::cout << rhs;
  }

  return *this;
}

#pragma message "Find a way to intelligently disable standard logging when it logs to stdout and curses is enabled"

#define LogToChannel(channel, msg) \
  do { \
    if(Log::IsChannelEnabled(channel)) { \
      Log::GetLogStream() << msg << "\n"; \
      Log::Flush(); \
      if(CurseMe::Enabled()) { \
        NCLogToChannel(channel, msg); \
      } \
    } \
  } while(false)


#define Debug(msg) LogToChannel(LOG_DEBUG,   msg)
#define Info(msg)  LogToChannel(LOG_INFO,    msg)
#define Warn(msg)  LogToChannel(LOG_WARNING, msg)
#define Error(msg) LogToChannel(LOG_ERROR,   msg)

#endif
