#ifndef __MTGP11213_H
#define __MTGP11213_H

/**
 * @file MTGP11213.hcl
 * 
 * @brief This generator is an OpenCL implementation of the generator no. 1 with sequence period (2^11213 - 1) taken from MTGP32 designed by Mutsuo Saito and Makoto Matsumoto (http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MTGP/index.html). The header provides all commonly used functions and macros, wich can be used together with MTGP11213 operating on local or global memory. The local work size has to be smaller than 265 work-items per work-group.
 *
 * @author Philipp Otterbein
 */ 

#include "random.hcl"

#ifndef __MTGP11213_LENGTH
	#define __MTGP11213_LENGTH 351
#endif
#define M 84
#define MASK 0xfff80000
#define SH1 12 
#define SH2 4


__constant uint __mtgp11213_tbl[] =  { 0x00000000, 0x71588353, 0xdfa887c1, 0xaef00492, 0x4ba66c6e, 0x3afeef3d, 0x940eebaf, 0xe55668fc, 0xa53da0ae, 0xd46523fd, 0x7a95276f, 0x0bcda43c, 0xee9bccc0, 0x9fc34f93, 0x31334b01, 0x406bc852 };

__constant uint __mtgp11213_temper_tbl[] = {0x00000000, 0x200040bb, 0x1082c61e, 0x308286a5, 0x10021c03, 0x30025cb8, 0x0080da1d, 0x20809aa6, 0x0003f0b9, 0x2003b002, 0x108136a7, 0x3081761c, 0x1001ecba, 0x3001ac01, 0x00832aa4, 0x20836a1f};

__constant uint __mtgp11213_float_temper_tbl[] = {0x3f800000, 0x3f900020, 0x3f884163, 0x3f984143, 0x3f88010e, 0x3f98012e, 0x3f80406d, 0x3f90404d, 0x3f8001f8, 0x3f9001d8, 0x3f88409b, 0x3f9840bb, 0x3f8800f6, 0x3f9800d6, 0x3f804195, 0x3f9041b5};



inline void MTGP11213_save( MTGP11213_PRNG prng );
inline uint __MTGP11213_random_wo_barrier( MTGP11213_PRNG prng, const bool sync );
inline uint __MTGP11213_random( MTGP11213_PRNG prng, bool sync );
inline uint __MTGP11213_randomT( MTGP11213_PRNG prng, bool sync );
inline float __MTGP11213_rndFloatT( MTGP11213_PRNG prng, bool sync );
inline float __MTGP11213_srndFloatT( MTGP11213_PRNG prng, bool sync );



/**
 * This function creates a tempered, uniformly distributed random integer using the MTGP11213_PRNG object \b prng
 * @param prng MTGP11213_PRNG object to use for random number generation
 * @return 32bit random number
 */ 
inline uint MTGP11213_random( MTGP11213_PRNG prng )
{
	return __MTGP11213_random( prng, false ); 
}



/**
 * This function creates a tempered, uniformly distributed random integer using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use for random number generation
 * @return tempered 32bit random number
 */ 
inline uint MTGP11213_randomT( MTGP11213_PRNG prng )
{
	return __MTGP11213_randomT( prng, false );
}


/**
 * \internal
 * This macro provides the code for the function 'float MTGP11213_[s]rndFloat( MTGP11213_PRNG );' returning random floats in the interval [0,1)
 */
__rnd_float_sync( MTGP11213, );


/**
 * This function creates tempered, uniformly distributed unsigned random floats using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use
 * @return tempered random float in the interval [0,1)
 */
inline float MTGP11213_rndFloatT( MTGP11213_PRNG prng )
{
	return __MTGP11213_rndFloatT( prng, false );
}




/**
 * This function creates tempered, uniformly distributed signed random floats using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use
 * @return tempered random float in the interval [-1,1)
 */
inline float MTGP11213_srndFloatT( MTGP11213_PRNG prng )
{
	return __MTGP11213_srndFloatT( prng, false );
}


#include "normal_random_float.hcl"
__box_muller_float_fast( MTGP11213, );
__box_muller_float_fast( MTGP11213, T );


#ifndef DISABLE_DOUBLES
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
/**
 * \internal
 * This macro provides code for functions 'double MTGP11213_[s]rndDouble32( MTGP11213_PRNG );' returning random doubles with random 32bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double32_sync( MTGP11213, );

/**
 * \internal
 * This macro provides code for functions 'double MTGP11213_[s]rndDouble32T( MTGP11213_PRNG );' returning tempered random doubles with random 32bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double32_sync( MTGP11213, T );

/**
 * \internal
 * This macro provides code for functions 'double MTGP11213_[s]rndDouble( MTGP11213_PRNG );' returning random doubles with random 52bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double_sync( MTGP11213, );

/**
 * \internal
 * This macro provides code for functions 'double MTGP11213_[s]rndDoubleT( MTGP11213_PRNG );' returning tempered random doubles with random 52bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double_sync( MTGP11213, T );

#include "normal_random_double.hcl"
__box_muller_double_fast( MTGP11213, );
__box_muller_double_fast( MTGP11213, T );
#endif

/**
 * \internal
 * The following methods are created here:
 *     inline int MTGP11213_random[T]_interval( MTGP11213_PRNG, int min, int max );
 *     inline int MTGP11213_random[T]_intervalX( MTGP11213_PRNG, int min, int max );
 *     inline int MTGP11213_random[T]_intervalX_const( MTGP11213_PRNG, int min, int max );
 * For documentation: see random.hcl
 */
__rnd_int_interval( MTGP11213, );
__rnd_int_interval( MTGP11213, T );
__rnd_int_intervalX_sync( MTGP11213, );
__rnd_int_intervalX_sync( MTGP11213, T );
__rnd_int_intervalX_const_sync( MTGP11213, );
__rnd_int_intervalX_const_sync( MTGP11213, T );



#ifdef DOXYGEN	
	__rnd_random_rejection_doc(MTGP11213, );
	__rnd_random_rejection_doc(MTGP11213, T);
	__rnd_rnd_rejection_doc(MTGP11213, , float, Float);
	__rnd_rnd_rejection_doc(MTGP11213, T, float, Float);
	__rnd_rnd_rejection_doc(MTGP11213, , double, Double);
	__rnd_rnd_rejection_doc(MTGP11213, T, double, Double);
	__rnd_rnd_rejection_doc(MTGP11213, , double, Double32);
	__rnd_rnd_rejection_doc(MTGP11213, T, double, Double32);
	__rnd_srnd_rejection_doc(MTGP11213, , float, Float);
	__rnd_srnd_rejection_doc(MTGP11213, T, float, Float);
	__rnd_srnd_rejection_doc(MTGP11213, , double, Double);
	__rnd_srnd_rejection_doc(MTGP11213, T, double, Double);
	__rnd_srnd_rejection_doc(MTGP11213, , double, Double32);
	__rnd_srnd_rejection_doc(MTGP11213, T, double, Double32);
	__rnd_interval_rejection_doc(MTGP11213, , );
	__rnd_interval_rejection_doc(MTGP11213, T, );
	__rnd_interval_rejection_doc(MTGP11213, , X);
	__rnd_interval_rejection_doc(MTGP11213, T, X);
	__rnd_interval_rejection_doc(MTGP11213, , X_const);
	__rnd_interval_rejection_doc(MTGP11213, T, X_const);
	__rnd_random_rejection_complex_doc(MTGP11213, );
	__rnd_random_rejection_complex_doc(MTGP11213, T);
	__rnd_rnd_rejection_complex_doc(MTGP11213, , float, Float);
	__rnd_rnd_rejection_complex_doc(MTGP11213, T, float, Float);
	__rnd_rnd_rejection_complex_doc(MTGP11213, , double, Double);
	__rnd_rnd_rejection_complex_doc(MTGP11213, T, double, Double);
	__rnd_rnd_rejection_complex_doc(MTGP11213, , double, Double32);
	__rnd_rnd_rejection_complex_doc(MTGP11213, T, double, Double32);
	__rnd_srnd_rejection_complex_doc(MTGP11213, , float, Float);
	__rnd_srnd_rejection_complex_doc(MTGP11213, T, float, Float);
	__rnd_srnd_rejection_complex_doc(MTGP11213, , double, Double);
	__rnd_srnd_rejection_complex_doc(MTGP11213, T, double, Double);
	__rnd_srnd_rejection_complex_doc(MTGP11213, , double, Double32);
	__rnd_srnd_rejection_complex_doc(MTGP11213, T, double, Double32);
	__rnd_interval_rejection_complex_doc(MTGP11213, , );
	__rnd_interval_rejection_complex_doc(MTGP11213, T, );
	__rnd_interval_rejection_complex_doc(MTGP11213, , X);
	__rnd_interval_rejection_complex_doc(MTGP11213, T, X);
	__rnd_interval_rejection_complex_doc(MTGP11213, , X_const);
	__rnd_interval_rejection_complex_doc(MTGP11213, T, X_const);
	
	
	__rnd_random_filter_doc(MTGP11213, );
	__rnd_random_filter_doc(MTGP11213, T);
	__rnd_rnd_filter_doc(MTGP11213, , float, Float);
	__rnd_rnd_filter_doc(MTGP11213, T, float, Float);
	__rnd_rnd_filter_doc(MTGP11213, , double, Double);
	__rnd_rnd_filter_doc(MTGP11213, T, double, Double);
	__rnd_rnd_filter_doc(MTGP11213, , double, Double32);
	__rnd_rnd_filter_doc(MTGP11213, T, double, Double32);
	__rnd_srnd_filter_doc(MTGP11213, , float, Float);
	__rnd_srnd_filter_doc(MTGP11213, T, float, Float);
	__rnd_srnd_filter_doc(MTGP11213, , double, Double);
	__rnd_srnd_filter_doc(MTGP11213, T, double, Double);
	__rnd_srnd_filter_doc(MTGP11213, , double, Double32);
	__rnd_srnd_filter_doc(MTGP11213, T, double, Double32);
	__rnd_interval_filter_doc(MTGP11213, , );
	__rnd_interval_filter_doc(MTGP11213, T, );
	__rnd_interval_filter_doc(MTGP11213, , X);
	__rnd_interval_filter_doc(MTGP11213, T, X);
	__rnd_interval_filter_doc(MTGP11213, , X_const);
	__rnd_interval_filter_doc(MTGP11213, T, X_const);
	__rnd_random_filter_complex_doc(MTGP11213, )
	__rnd_random_filter_complex_doc(MTGP11213, T)
	__rnd_rnd_filter_complex_doc(MTGP11213, , float, Float);
	__rnd_rnd_filter_complex_doc(MTGP11213, T, float, Float);
	__rnd_rnd_filter_complex_doc(MTGP11213, , double, Double);
	__rnd_rnd_filter_complex_doc(MTGP11213, T, double, Double);
	__rnd_rnd_filter_complex_doc(MTGP11213, , double, Double32);
	__rnd_rnd_filter_complex_doc(MTGP11213, T, double, Double32);
	__rnd_srnd_filter_complex_doc(MTGP11213, , float, Float);
	__rnd_srnd_filter_complex_doc(MTGP11213, T, float, Float);
	__rnd_srnd_filter_complex_doc(MTGP11213, , double, Double);
	__rnd_srnd_filter_complex_doc(MTGP11213, T, double, Double);
	__rnd_srnd_filter_complex_doc(MTGP11213, , double, Double32);
	__rnd_srnd_filter_complex_doc(MTGP11213, T, double, Double32);
	__rnd_interval_filter_complex_doc(MTGP11213, , );
	__rnd_interval_filter_complex_doc(MTGP11213, T, );
	__rnd_interval_filter_complex_doc(MTGP11213, , X);
	__rnd_interval_filter_complex_doc(MTGP11213, T, X);
	__rnd_interval_filter_complex_doc(MTGP11213, , X_const);
	__rnd_interval_filter_complex_doc(MTGP11213, T, X_const);
#endif



#if ( !(defined DOXYGEN) && !(defined DISABLE_VAR_MACROS) )
/**
 * This macro is a wrapper for __rnd_rejection
 */
#define MTGP11213_generic_rejection( return_type, prng_method, dest, prng, comparison, ... ) __rnd_rejection( return_type, prng_method, (dest), prng, comparison, ##__VA_ARGS__ )

/**
 * The macro MTGP11213_<method>_rejection creates a rejection loop which returns a random number created by MTGP11213_<method> and accepeted by a comparison method. MTGP11213_<method> has to have one argument
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param comparison comparison method which decides whether to accept random number or not. It has the signature 'bool \b comparison( return type of MTGP11213_<method>, ...)' and its first argument is the random number generated by MTGP11213_<method>
 * @param ... this optional arguments are redirected to \b comparison
 */
#define MTGP11213_random_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( uint, MTGP11213_random, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( uint, MTGP11213_randomT, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloat_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( float, MTGP11213_rndFloat, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloatT_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( float, MTGP11213_rndFloatT, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloat_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( float, MTGP11213_srndFloat, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloatT_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( float, MTGP11213_srndFloatT, (dest), prng, comparison, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MTGP11213_rndDouble32_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_rndDouble32, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble32T_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_rndDouble32T, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_srndDouble32, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32T_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_srndDouble32T, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_rndDouble, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDoubleT_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_rndDoubleT, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_srndDouble, (dest), prng, comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDoubleT_rejection( dest, prng, comparison, ... ) __rnd_rejection_sync( double, MTGP11213_srndDoubleT, (dest), prng, comparison, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_rejection_interval
 */
#define MTGP11213_generic_interval_rejection( return_type, prng_method, dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( return_type, prng_method, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )

/**
 * The macro MTGP11213_random[T]_interval[{X,X_const}]_rejection creates a rejection loop which returns a random integer created by MTGP11213_random[T]_interval[{X,X_const}] and accepeted by a comparison method.
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of the random integer created by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of the random integer created by MTGP11213_random[T]_interval[{X,X_const}]
 * @param comparison comparison method which decides whether to accept random number or not. It has the signature 'bool \b comparison( int, ...)' and its first argument is the random integer generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param ... this optional arguments are redirected to \b comparison
 */ 
#define MTGP11213_random_interval_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_random_interval, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_interval_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_randomT_interval, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_random_intervalX, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_randomT_intervalX, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_const_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_random_intervalX_const, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_const_rejection( dest, prng, min, max, comparison, ... ) __rnd_rejection_interval_sync( int, MTGP11213_randomT_intervalX_const, (dest), prng, (min), (max), comparison, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_rejection_complex
 */
#define MTGP11213_generic_rejection_complex( return_type, prng_method, dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( return_type, prng_method, (dest), prng, (n), comparison, ##__VA_ARGS__ )

/**
 * The macro MTGP11213_<method>_rejection_complex creates a rejection loop which returns a result chosen by a comparison method and is derived from \b n random numbers generated by MTGP11213_<method>. MTGP11213_<method> has to have one argument
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b comparison.
 * @param comparison comparison method which decides whether to accept random number or not and stores them in \b dest. It has the signature 'bool \b comparison( __private typeof(\b dest), const 'return type of MTGP11213_<method>' *const, ...)' and its first argument is the array of \b n random numbers generated by MTGP11213_<method>
 * @param ... this optional arguments are redirected to \b comparison
 */ 
#define MTGP11213_random_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( uint, MTGP11213_random, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( uint, MTGP11213_randomT, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloat_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( float, MTGP11213_rndFloat, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloatT_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( float, MTGP11213_rndFloatT, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloat_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( float, MTGP11213_srndFloat, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloatT_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( float, MTGP11213_srndFloatT, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MTGP11213_rndDouble32_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_rndDouble32, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble32T_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_rndDouble32T, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_srndDouble32, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32T_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_srndDouble32T, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_rndDouble, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDoubleT_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_rndDoubleT, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_srndDouble, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDoubleT_rejection_complex( dest, prng, n, comparison, ... ) __rnd_rejection_complex_sync( double, MTGP11213_srndDoubleT, (dest), prng, (n), comparison, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_interval_rejection_complex
 */
#define MTGP11213_generic_interval_rejection_complex( return_type, prng_method, dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( return_type, prng_method, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )

/**
 * The macro MTGP11213_random[T]_interval[{X,X_const}]_rejection_complex creates a rejection loop which returns a result chosen by a comparison method and derived from \b n random integers generated by MTGP11213_random[T]_interval[{X,X_const}].
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of random integer generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of random integer generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b comparison.
 * @param comparison comparison method which decides whether to accept random number or not and stores them in \b dest. It has the signature 'bool \b comparison( __private typeof(\b dest), const int* const, ...)' and its first argument is the array of \b n random integers generated by MTGP11213_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b comparison
 */ 
#define MTGP11213_random_interval_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_random_interval, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_interval_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_randomT_interval, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_random_intervalX, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_randomT_intervalX, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_const_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_random_intervalX_const, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_const_rejection_complex( dest, prng, min, max, n, comparison, ... ) __rnd_rejection_interval_complex_sync( int, MTGP11213_randomT_intervalX_const, (dest), prng, (min), (max), (n), comparison, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_filter
 */
#define MTGP11213_generic_filter( prng_method, dest, prng, temp_array, comparison, ... ) __rnd_filter( prng_method, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )

/**
 * The MTGP11213_<method>_filter returns random numbers generated by MTGP11213_<method> which are accepted by a comparison method. MTGP11213_<method> has to have one argument
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param comparison comparison method wich decides whether to accept a random number or not. It has the signature 'bool \b comparison( return type of MTGP11213_<method>, ...)' and its first argument is the random number generated by MTGP11213_<method>
 * @param ... this optional arguments are redirected to \b comparison
 */
#define MTGP11213_random_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_random, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_randomT, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloat_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndFloat, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloatT_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndFloatT, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloat_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndFloat, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloatT_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndFloatT, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MTGP11213_rndDouble32_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndDouble32, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble32T_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndDouble32T, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndDouble32, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32T_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndDouble32T, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndDouble, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDoubleT_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_rndDoubleT, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndDouble, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDoubleT_filter( dest, prng, temp_array, comparison, ... ) __rnd_filter( MTGP11213_srndDoubleT, (dest), prng, (temp_array), comparison, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_filter_interval
 */
#define MTGP11213_generic_interval_filter( prng_method, dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( prng_method, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )

/**
 * The MTGP11213_random[T]_interval[{X,X_const}]_filter returns random integers generated by MTGP11213_random[T]_interval[{X,X_const}] which are accepted by a comparison method.
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of random integer generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of random integer generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param comparison comparison method wich decides whether to accept a random number or not. It has the signature 'bool \b comparison( int, ...)' and its first argument is the random number generated by MTGP11213_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b comparison
 */
#define MTGP11213_random_interval_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_random_interval, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_interval_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_randomT_interval, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_random_intervalX, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_randomT_intervalX, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_const_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_random_intervalX_const, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_const_filter( dest, prng, min, max, temp_array, comparison, ... ) __rnd_filter_interval( MTGP11213_randomT_intervalX_const, (dest), prng, (min), (max), (temp_array), comparison, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_filter_complex
 */
#define MTGP11213_generic_filter_complex( return_type, prng_method, dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( return_type, prng_method, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )

/**
 * The MTGP11213_<method>_filter_complex returns a result which is chosen by a comparison method and derived from \b n random numbers generated by MTGP11213_<method>. MTGP11213_<method> has to have one argument
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b comparison.
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param comparison comparison method wich decides whether to accept a result or not. It has the signature 'bool \b comparison( __private typeof(\b dest), const 'return type of MTGP11213_<method>' *const, ...)' and \b comparison has to write its results to the first argument. The second argument is the array of \b n random numbers generated by MTGP11213_<method>
 * @param ... this optional arguments are redirected to \b comparison
 */
#define MTGP11213_random_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( uint, MTGP11213_random, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( uint, MTGP11213_randomT, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloat_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( float, MTGP11213_rndFloat, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndFloatT_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( float, MTGP11213_rndFloatT, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloat_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( float, MTGP11213_srndFloat, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndFloatT_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( float, MTGP11213_srndFloatT, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MTGP11213_rndDouble32_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_rndDouble32, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble32T_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_rndDouble32T, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_srndDouble32, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble32T_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_srndDouble32T, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDouble_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_rndDouble, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_rndDoubleT_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_rndDoubleT, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDouble_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_srndDouble, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_srndDoubleT_filter_complex( dest, prng, n, temp_array, comparison, ... ) __rnd_filter_complex( double, MTGP11213_srndDoubleT, (dest), prng, (n), (temp_array), comparison, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_filter_interval_complex
 */
#define MTGP11213_generic_interval_filter_complex( return_type, prng_method, dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( return_type, prng_method, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )

/**
 * The MTGP11213_random[T]_interval[{X,X_const}]_filter_complex returns a result which is chosen by a comparison method and derived from \b n random integers generated by MTGP11213_random[T]_interval[{X,X_const}].
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min int, lower bound of random integers generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] max int, upper bound of random integers generated by MTGP11213_random[T]_interval[{X,X_const}]
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b comparison.
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param comparison comparison method wich decides whether to accept a result or not. It has the signature 'bool \b comparison( __private typeof(\b dest), const int *const, ...)' and \b comparison has to write its results to the first argument. The second argument are the \b n random numbers generated by MTGP11213_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b comparison
 */
#define MTGP11213_random_interval_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_random_interval, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_interval_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_randomT_interval, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_random_intervalX, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_randomT_intervalX, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_random_intervalX_const_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_random_intervalX_const, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )
#define MTGP11213_randomT_intervalX_const_filter_complex( dest, prng, min, max, n, temp_array, comparison, ... ) __rnd_filter_interval_complex( int, MTGP11213_randomT_intervalX_const, (dest), prng, (min), (max), (n), (temp_array), comparison, ##__VA_ARGS__ )


#endif



#ifndef DISABLE_VAR_MACROS
#ifndef DISABLE_DOUBLES
/**
 * \internal
 * The following methods are created here:
 *     inline double MTGP11213_exp_distr_double[T][_fast]( MTGP11213_PRNG );
 */
__rnd_exp_distr_double_sync( MTGP11213, );
__rnd_exp_distr_double_sync( MTGP11213, T );

__box_muller_double( MTGP11213, );
__box_muller_double( MTGP11213, T );

#if ((defined ZIGGURAT_NORMAL) || (defined ZIGGURAT_NORMAL_DOUBLE))
	__ziggurat_normal_double( MTGP11213, );
	__ziggurat_normal_double( MTGP11213, T );
#endif
#endif


/**
 * \internal
 * The following methods are created here:
 *     inline float MTGP11213_exp_distr_float[T]( MTGP11213_PRNG );
 */
__rnd_exp_distr_float_sync( MTGP11213, );
__rnd_exp_distr_float_sync( MTGP11213, T );

__box_muller_float( MTGP11213, );
__box_muller_float( MTGP11213, T );
__box_muller_float_native( MTGP11213, );
__box_muller_float_native( MTGP11213, T );

#if ((defined ZIGGURAT_NORMAL) || (defined ZIGGURAT_NORMAL_FLOAT))
	__ziggurat_normal_float( MTGP11213, );
	__ziggurat_normal_float( MTGP11213, T );
#endif
#endif



#endif