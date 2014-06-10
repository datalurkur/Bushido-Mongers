#ifndef LOG_H
#define LOG_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <set>
#include <mutex>

#include "util/config.h"
#include "util/timestamp.h"

using namespace std;

#define LOG_DEBUG   0x01
#define LOG_INFO    0x02
#define LOG_WARNING 0x04
#define LOG_ERROR   0x08

typedef char LogChannel;

class LogListener {
public:
  virtual void logMessage(LogChannel channel, const string& message) = 0;
};

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

  static void RegisterListener(LogListener* listener);
  static void UnregisterListener(LogListener* listener);
  static void SendToListeners(LogChannel channel, const string& message);

  static void EnableStdout();
  static void DisableStdout();

  static mutex Mutex;

public:
  Log(const string& logfile = "bm.log");
  virtual ~Log();

  void flush();

  template <typename T>
  Log& operator<<(const T &rhs);

private:
  static Log *OutputStream;
  static LogChannel ChannelState;
  static bool StdoutEnabled;
  static set<LogListener*> Listeners;

private:
  bool _cleanupStream;
  ostream *_outputStream;
  filebuf *_logFile;
};

template <typename T>
Log& Log::operator<<(const T &rhs) {
  (*_outputStream) << rhs;

  if(StdoutEnabled) {
    cout << rhs;
  }

  return *this;
}

#define LogToChannel(channel, msg) \
  do { \
    unique_lock<mutex> lock(Log::Mutex); \
    if(Log::IsChannelEnabled(channel)) { \
      Log::GetLogStream() << "[" << __FILE__ << ":" << __LINE__ << " | " << Clock.getTime() << "] " << msg << "\n"; \
      Log::Flush(); \
      ostringstream stream; \
      stream << msg; \
      Log::SendToListeners(channel, stream.str()); \
    } \
  } while(false)

#define Debug(msg) LogToChannel(LOG_DEBUG,   msg)
#define Info(msg)  LogToChannel(LOG_INFO,    msg)
#define Warn(msg)  LogToChannel(LOG_WARNING, msg)
#define Error(msg) LogToChannel(LOG_ERROR,   msg)

#endif
