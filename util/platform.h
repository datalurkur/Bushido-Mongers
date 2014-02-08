#ifndef PLATFORM_H
#define PLATFORM_H

#define PLATFORM_APPLE 0
#define PLATFORM_WIN32 1
#define PLATFORM_LINUX 2

#if defined(__APPLE__) && defined(__MACH__)
# define SYS_PLATFORM PLATFORM_APPLE
#elif defined( __WIN32__ ) || defined( _WIN32 )
# define SYS_PLATFORM PLATFORM_WIN32
#else
# define SYS_PLATFORM PLATFORM_LINUX
#endif

#endif
