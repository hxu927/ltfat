  //#include "fftw3.h"

#ifdef LTFAT_COMPLEX
   #undef LTFAT_COMPLEX
#endif
#ifdef LTFAT_REAL
   #undef LTFAT_REAL
#endif
#ifdef LTFAT_TYPE
   #undef LTFAT_TYPE
#endif
#ifdef LTFAT_NAME
   #undef LTFAT_NAME
#endif
#ifdef LTFAT_FFTW
   #undef LTFAT_FFTW
#endif

#ifdef LTFAT_MX_CLASSID
   #undef LTFAT_MX_CLASSID
#endif

#ifdef LTFAT_MX_COMPLEXITY
   #undef LTFAT_MX_COMPLEXITY
#endif

#ifdef LTFAT_COMPLEXH
   #undef LTFAT_COMPLEXH
#endif

#if defined(LTFAT_DOUBLE)
#  define LTFAT_REAL double
#  define LTFAT_MX_CLASSID mxDOUBLE_CLASS
#  define LTFAT_FFTW(name) fftw_ ## name
#  if defined(LTFAT_COMPLEXTYPE)
#    define LTFAT_COMPLEX double _Complex
#    define LTFAT_COMPLEXH LTFAT_COMPLEX
#    define LTFAT_TYPE LTFAT_COMPLEX
#    define LTFAT_NAME(name) cd_ ## name
#    define LTFAT_MX_COMPLEXITY mxCOMPLEX
#  else
//#    define LTFAT_COMPLEX double _Complex
#    define LTFAT_COMPLEX fftw_complex
#    define LTFAT_COMPLEXH double _Complex
#    define LTFAT_TYPE LTFAT_REAL
#    define LTFAT_NAME(name) d_ ## name
#    define LTFAT_MX_COMPLEXITY mxREAL
#  endif
#endif

#ifdef LTFAT_SINGLE
#define LTFAT_REAL float
#define LTFAT_MX_CLASSID mxSINGLE_CLASS
#define LTFAT_FFTW(name) fftwf_ ## name
#  if defined(LTFAT_COMPLEXTYPE)
#    define LTFAT_COMPLEX float _Complex
#    define LTFAT_COMPLEXH LTFAT_COMPLEX
#    define LTFAT_TYPE LTFAT_COMPLEX
#    define LTFAT_NAME(name) cs_ ## name
#    define LTFAT_MX_COMPLEXITY mxCOMPLEX
#  else
#    define LTFAT_COMPLEX fftwf_complex
//#    define LTFAT_COMPLEX float _Complex
#    define LTFAT_COMPLEXH float _Complex
#    define LTFAT_TYPE LTFAT_REAL
#    define LTFAT_NAME(name) s_ ## name
#    define LTFAT_MX_COMPLEXITY mxREAL
#  endif
#endif

/*
  If compiled using C++
*/
/*
#ifdef __cplusplus
#  undef LTFAT_NAME
#  define LTFAT_NAME(name) name
#endif // __cplusplus
*/
