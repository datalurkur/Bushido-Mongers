#ifndef ASSERTION_H
#define ASSERTION_H

#include "util/log.h"

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

#if SYS_PLATFORM == PLATFORM_APPLE
# define ASSERT_FUNCTION __asm__("int $03")
#elif SYS_PLATFORM == PLATFORM_WIN32
# define ASSERT_FUNCTION __asm { int 3 }
#else
# include <assert.h>
# define ASSERT(conditional, message) assert(conditional)
#endif

#ifndef ASSERT
# ifdef DEBUG
#  define ASSERT(conditional, message) \
    do { \
      if(!(conditional)) { \
        Error("Assertion in " << __FILE__ << ":" << __LINE__ << " hit : " << message); \
        ASSERT_FUNCTION; \
      } \
    } while(false)
# else
#  define ASSERT(conditional, message) do { } while(false)
# endif
#endif

#endif
