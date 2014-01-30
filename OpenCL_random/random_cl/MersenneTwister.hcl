#ifndef __MT_H
#define __MT_H


/**
 * @file MersenneTwister.hcl
 * 
 * @brief This header file provides all commonly used functions and macros, which can be used together with the Mersenne-Twister algorithm operating on local or global memory. Functions, which function name contains 'T', use a tempered Mersenne-Twister algorithm for random number generation. The local work size has to be smaller than 226 work-items per work-group.
 * 
 * @author Philipp Otterbein
 */


#include "random.hcl"


#ifndef __MT_LENGTH
	#define __MT_LENGTH 624
#endif
#define M 397
#define HIGH_MASK 0x80000000
#define LOW_MASK 0x7fffffff


inline void MT_save( MT_PRNG );
inline uint __MT_random( MT_PRNG, bool ); /**< \internal */



/**
 * This function creates a random integer using the MT_PRNG object \b prng
 * @param prng MT_PRNG object to use for random number generation
 * @return 32bit random number
 */ 
inline uint MT_random( MT_PRNG prng )
{
	return __MT_random( prng, false ); 
}


/**
 * \internal
 * This internal function creates a tempered random integer using the MT_PRNG object \b prng
 * @param prng PRNG object to use for random number generation
 * @param sync specifies whether to set \b prng .sync[1]
 * @return tempered random integer
 */
inline uint __MT_randomT( MT_PRNG prng, bool sync )
{
	uint h = __MT_random( prng, sync );
	h ^= (h >> 11);
	h ^= (h << 7) & 0x9d2c5680;
	h ^= (h << 15) & 0xefc60000;
	h ^= (h >> 18);
	return h;
}


/**
 * This function creates a tempered random integer using the MT_PRNG object \b prng
 * @param prng PRNG object to use for random number generation
 * @return tempered 32bit random integer
 */ 
inline uint MT_randomT( MT_PRNG prng )
{
	return __MT_randomT( prng, false );
}


/**
 * \internal
 * This macros provide the code for the function 'float MT_[s]rndFloat[T]( MT_PRNG );' returning random floats in the interval [0,1)
 */
__rnd_float_sync( MT, );
__rnd_float_sync( MT, T );


#include "normal_random_float.hcl"
__box_muller_float_fast( MT, );
__box_muller_float_fast( MT, T );


#ifndef DISABLE_DOUBLES
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
/**
 * \internal
 * This macro provides code for functions 'double MT_[s]rndDouble32( MT_PRNG );' returning random doubles with random 32bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double32_sync( MT, );

/**
 * \internal
 * This macro provides code for functions 'double MT_[s]rndDouble32T( MT_PRNG );' returning tempered random doubles with random 32bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double32_sync( MT, T );

/**
 * \internal
 * This macro provides code for functions 'double MT_[s]rndDouble( MT_PRNG );' returning random doubles with random 52bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double_sync( MT, );

/**
 * \internal
 * This macro provides code for functions 'double MT_[s]rndDoubleT( MT_PRNG );' returning tempered random doubles with random 52bit mantissa in the interval [0,1) or [-1,1)
 */
__rnd_double_sync( MT, T );

#include "normal_random_double.hcl"
__box_muller_double_fast( MT, );
__box_muller_double_fast( MT, T );
#endif

/**
 * \internal
 * The following methods are created here:
 *     inline int MT_random[T]_interval( MT_PRNG, int min, int max );
 *     inline int MT_random[T]_intervalX( MT_PRNG, int min, int max );
 *     inline int MT_random[T]_intervalX_const( MT_PRNG, int min, int max );
 * For documentation: see random.hcl
 */
__rnd_int_interval( MT, );
__rnd_int_interval( MT, T );
__rnd_int_intervalX_sync( MT, );
__rnd_int_intervalX_sync( MT, T );
__rnd_int_intervalX_const_sync( MT, );
__rnd_int_intervalX_const_sync( MT, T );



#ifdef DOXYGEN	
	__rnd_random_rejection_doc(MT, );
	__rnd_random_rejection_doc(MT, T);
	__rnd_rnd_rejection_doc(MT, , float, Float);
	__rnd_rnd_rejection_doc(MT, T, float, Float);
	__rnd_rnd_rejection_doc(MT, , double, Double);
	__rnd_rnd_rejection_doc(MT, T, double, Double);
	__rnd_rnd_rejection_doc(MT, , double, Double32);
	__rnd_rnd_rejection_doc(MT, T, double, Double32);
	__rnd_srnd_rejection_doc(MT, , float, Float);
	__rnd_srnd_rejection_doc(MT, T, float, Float);
	__rnd_srnd_rejection_doc(MT, , double, Double);
	__rnd_srnd_rejection_doc(MT, T, double, Double);
	__rnd_srnd_rejection_doc(MT, , double, Double32);
	__rnd_srnd_rejection_doc(MT, T, double, Double32);
	__rnd_interval_rejection_doc(MT, , );
	__rnd_interval_rejection_doc(MT, T, );
	__rnd_interval_rejection_doc(MT, , X);
	__rnd_interval_rejection_doc(MT, T, X);
	__rnd_interval_rejection_doc(MT, , X_const);
	__rnd_interval_rejection_doc(MT, T, X_const);
	__rnd_random_rejection_complex_doc(MT, );
	__rnd_random_rejection_complex_doc(MT, T);
	__rnd_rnd_rejection_complex_doc(MT, , float, Float);
	__rnd_rnd_rejection_complex_doc(MT, T, float, Float);
	__rnd_rnd_rejection_complex_doc(MT, , double, Double);
	__rnd_rnd_rejection_complex_doc(MT, T, double, Double);
	__rnd_rnd_rejection_complex_doc(MT, , double, Double32);
	__rnd_rnd_rejection_complex_doc(MT, T, double, Double32);
	__rnd_srnd_rejection_complex_doc(MT, , float, Float);
	__rnd_srnd_rejection_complex_doc(MT, T, float, Float);
	__rnd_srnd_rejection_complex_doc(MT, , double, Double);
	__rnd_srnd_rejection_complex_doc(MT, T, double, Double);
	__rnd_srnd_rejection_complex_doc(MT, , double, Double32);
	__rnd_srnd_rejection_complex_doc(MT, T, double, Double32);
	__rnd_interval_rejection_complex_doc(MT, , );
	__rnd_interval_rejection_complex_doc(MT, T, );
	__rnd_interval_rejection_complex_doc(MT, , X);
	__rnd_interval_rejection_complex_doc(MT, T, X);
	__rnd_interval_rejection_complex_doc(MT, , X_const);
	__rnd_interval_rejection_complex_doc(MT, T, X_const);
	
	
	__rnd_random_filter_doc(MT, );
	__rnd_random_filter_doc(MT, T);
	__rnd_rnd_filter_doc(MT, , float, Float);
	__rnd_rnd_filter_doc(MT, T, float, Float);
	__rnd_rnd_filter_doc(MT, , double, Double);
	__rnd_rnd_filter_doc(MT, T, double, Double);
	__rnd_rnd_filter_doc(MT, , double, Double32);
	__rnd_rnd_filter_doc(MT, T, double, Double32);
	__rnd_srnd_filter_doc(MT, , float, Float);
	__rnd_srnd_filter_doc(MT, T, float, Float);
	__rnd_srnd_filter_doc(MT, , double, Double);
	__rnd_srnd_filter_doc(MT, T, double, Double);
	__rnd_srnd_filter_doc(MT, , double, Double32);
	__rnd_srnd_filter_doc(MT, T, double, Double32);
	__rnd_interval_filter_doc(MT, , );
	__rnd_interval_filter_doc(MT, T, );
	__rnd_interval_filter_doc(MT, , X);
	__rnd_interval_filter_doc(MT, T, X);
	__rnd_interval_filter_doc(MT, , X_const);
	__rnd_interval_filter_doc(MT, T, X_const);
	__rnd_random_filter_complex_doc(MT, )
	__rnd_random_filter_complex_doc(MT, T)
	__rnd_rnd_filter_complex_doc(MT, , float, Float);
	__rnd_rnd_filter_complex_doc(MT, T, float, Float);
	__rnd_rnd_filter_complex_doc(MT, , double, Double);
	__rnd_rnd_filter_complex_doc(MT, T, double, Double);
	__rnd_rnd_filter_complex_doc(MT, , double, Double32);
	__rnd_rnd_filter_complex_doc(MT, T, double, Double32);
	__rnd_srnd_filter_complex_doc(MT, , float, Float);
	__rnd_srnd_filter_complex_doc(MT, T, float, Float);
	__rnd_srnd_filter_complex_doc(MT, , double, Double);
	__rnd_srnd_filter_complex_doc(MT, T, double, Double);
	__rnd_srnd_filter_complex_doc(MT, , double, Double32);
	__rnd_srnd_filter_complex_doc(MT, T, double, Double32);
	__rnd_interval_filter_complex_doc(MT, , );
	__rnd_interval_filter_complex_doc(MT, T, );
	__rnd_interval_filter_complex_doc(MT, , X);
	__rnd_interval_filter_complex_doc(MT, T, X);
	__rnd_interval_filter_complex_doc(MT, , X_const);
	__rnd_interval_filter_complex_doc(MT, T, X_const);
#endif



#if ( !(defined DOXYGEN) && !(defined DISABLE_VAR_MACROS) )
/**
 * This macro is a wrapper for __rnd_rejection
 */
#define MT_generic_rejection( return_type, prng_method, dest, prng, acceptance_func, ... ) __rnd_rejection( return_type, prng_method, (dest), prng, acceptance_func, ##__VA_ARGS__ )

/**
 * The macro MT_<method>_rejection creates a rejection loop which returns a random number created by MT_<method> and accepeted by a acceptance method. MT_<method> has to have one argument
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param acceptance_func acceptance method which decides whether to accept random number or not. It has the signature 'bool \b acceptance_func( return type of MT_<method>, ...)' and its first argument is the random number generated by MT_<method>
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define MT_random_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( uint, MT_random, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( uint, MT_randomT, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloat_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( float, MT_rndFloat, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloatT_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( float, MT_rndFloatT, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloat_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( float, MT_srndFloat, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloatT_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( float, MT_srndFloatT, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MT_rndDouble32_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_rndDouble32, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble32T_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_rndDouble32T, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_srndDouble32, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32T_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_srndDouble32T, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_rndDouble, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_rndDoubleT_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_rndDoubleT, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_srndDouble, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#define MT_srndDoubleT_rejection( dest, prng, acceptance_func, ... ) __rnd_rejection_sync( double, MT_srndDoubleT, (dest), prng, acceptance_func, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_rejection_interval
 */
#define MT_generic_interval_rejection( return_type, prng_method, dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( return_type, prng_method, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )

/**
 * The macro MT_random[T]_interval[{X,X_const}]_rejection creates a rejection loop which returns a uniformly distributed random integer generated by MT_random[T]_interval[{X,X_const}] and accepeted by a acceptance method.
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of the random integer created by MT_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of the random integer created by MT_random[T]_interval[{X,X_const}]
 * @param acceptance_func acceptance method which decides whether to accept random number or not. It has the signature 'bool \b acceptance_func( int, ...)' and its first argument is the random integer generated by MT_random[T]_interval[{X,X_const}]
 * @param ... this optional arguments are redirected to \b acceptance_func
 */ 
#define MT_random_interval_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_random_interval, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_interval_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_randomT_interval, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_random_intervalX, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_randomT_intervalX, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_const_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_random_intervalX_const, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_const_rejection( dest, prng, min, max, acceptance_func, ... ) __rnd_rejection_interval_sync( int, MT_randomT_intervalX_const, (dest), prng, (min), (max), acceptance_func, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_rejection_complex
 */
#define MT_generic_rejection_complex( return_type, prng_method, dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( return_type, prng_method, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )

/**
 * The macro MT_<method>_rejection_complex creates a rejection loop which returns a result chosen by a acceptance method and is derived from \b n random numbers generated by MT_<method>. MT_<method> has to have one argument
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func.
 * @param acceptance_func acceptance method which decides whether to accept random number or not and stores them in \b dest. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const 'return type of MT_<method>' *const, ...)' and its first argument is the array of \b n random numbers generated by MT_<method>
 * @param ... this optional arguments are redirected to \b acceptance_func
 */ 
#define MT_random_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( uint, MT_random, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( uint, MT_randomT, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloat_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( float, MT_rndFloat, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloatT_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( float, MT_rndFloatT, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloat_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( float, MT_srndFloat, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloatT_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( float, MT_srndFloatT, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MT_rndDouble32_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_rndDouble32, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble32T_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_rndDouble32T, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_srndDouble32, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32T_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_srndDouble32T, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_rndDouble, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDoubleT_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_rndDoubleT, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_srndDouble, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDoubleT_rejection_complex( dest, prng, n, acceptance_func, ... ) __rnd_rejection_complex_sync( double, MT_srndDoubleT, (dest), prng, (n), acceptance_func, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_interval_rejection_complex
 */
#define MT_generic_interval_rejection_complex( return_type, prng_method, dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( return_type, prng_method, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )

/**
 * The macro MT_random[T]_interval[{X,X_const}]_rejection_complex creates a rejection loop which returns a result chosen by a acceptance method and derived from \b n random integers generated by MT_random[T]_interval[{X,X_const}].
 * @param[out] dest pointer to a memory location. result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of random integer generated by MT_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of random integer generated by MT_random[T]_interval[{X,X_const}]
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func.
 * @param acceptance_func acceptance method which decides whether to accept random number or not and stores them in \b dest. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const int* const, ...)' and its first argument is the array of \b n random integers generated by MT_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b acceptance_func
 */ 
#define MT_random_interval_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_random_interval, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_interval_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_randomT_interval, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_random_intervalX, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_randomT_intervalX, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_const_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_random_intervalX_const, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_const_rejection_complex( dest, prng, min, max, n, acceptance_func, ... ) __rnd_rejection_interval_complex_sync( int, MT_randomT_intervalX_const, (dest), prng, (min), (max), (n), acceptance_func, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_filter
 */
#define MT_generic_filter( prng_method, dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( prng_method, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )

/**
 * The MT_<method>_filter returns random numbers generated by MT_<method> which are accepted by a acceptance method. MT_<method> has to have one argument
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a random number or not. It has the signature 'bool \b acceptance_func( return type of MT_<method>, ...)' and its first argument is the random number generated by MT_<method>
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define MT_random_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_random, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_randomT, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloat_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndFloat, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloatT_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndFloatT, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloat_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndFloat, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloatT_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndFloatT, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MT_rndDouble32_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndDouble32, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble32T_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndDouble32T, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndDouble32, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32T_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndDouble32T, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndDouble, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDoubleT_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_rndDoubleT, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndDouble, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDoubleT_filter( dest, prng, temp_array, acceptance_func, ... ) __rnd_filter( MT_srndDoubleT, (dest), prng, (temp_array), acceptance_func, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_filter_interval
 */
#define MT_generic_interval_filter( prng_method, dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( prng_method, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )

/**
 * The MT_random[T]_interval[{X,X_const}]_filter returns random integers generated by MT_random[T]_interval[{X,X_const}] which are accepted by a acceptance method.
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of random integer generated by MT_random[T]_interval[{X,X_const}]
 * @param[in] max upper bound of random integer generated by MT_random[T]_interval[{X,X_const}]
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a random number or not. It has the signature 'bool \b acceptance_func( int, ...)' and its first argument is the random number generated by MT_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define MT_random_interval_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_random_interval, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_interval_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_randomT_interval, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_random_intervalX, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_randomT_intervalX, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_const_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_random_intervalX_const, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_const_filter( dest, prng, min, max, temp_array, acceptance_func, ... ) __rnd_filter_interval( MT_randomT_intervalX_const, (dest), prng, (min), (max), (temp_array), acceptance_func, ##__VA_ARGS__ )



/**
 * This macro is a wrapper for __rnd_filter_complex
 */
#define MT_generic_filter_complex( return_type, prng_method, dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( return_type, prng_method, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )

/**
 * The MT_<method>_filter_complex returns a result which is chosen by a acceptance method and derived from \b n random numbers generated by MT_<method>. MT_<method> has to have one argument
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func.
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a result or not. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const 'return type of MT_<method>' *const, ...)' and \b acceptance_func has to write its results to the first argument. The second argument is the array of \b n random numbers generated by MT_<method>
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define MT_random_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( uint, MT_random, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( uint, MT_randomT, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloat_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( float, MT_rndFloat, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndFloatT_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( float, MT_rndFloatT, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloat_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( float, MT_srndFloat, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndFloatT_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( float, MT_srndFloatT, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#ifndef DISABLE_DOUBLES
#define MT_rndDouble32_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_rndDouble32, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble32T_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_rndDouble32T, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_srndDouble32, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble32T_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_srndDouble32T, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDouble_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_rndDouble, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_rndDoubleT_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_rndDoubleT, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDouble_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_srndDouble, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_srndDoubleT_filter_complex( dest, prng, n, temp_array, acceptance_func, ... ) __rnd_filter_complex( double, MT_srndDoubleT, (dest), prng, (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#endif


/**
 * This macro is a wrapper for __rnd_filter_interval_complex
 */
#define MT_generic_interval_filter_complex( return_type, prng_method, dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( return_type, prng_method, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )

/**
 * The MT_random[T]_interval[{X,X_const}]_filter_complex returns a result which is chosen by a acceptance method and derived from \b n random integers generated by MT_random[T]_interval[{X,X_const}].
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min int, lower bound of random integers generated by MT_random[T]_interval[{X,X_const}]
 * @param[in] max int, upper bound of random integers generated by MT_random[T]_interval[{X,X_const}]
 * @param[in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func.
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted random numbers are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a result or not. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const int *const, ...)' and \b acceptance_func has to write its results to the first argument. The second argument are the \b n random numbers generated by MT_random[T]_interval[X]
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define MT_random_interval_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_random_interval, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_interval_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_randomT_interval, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_random_intervalX, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_randomT_intervalX, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_random_intervalX_const_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_random_intervalX_const, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )
#define MT_randomT_intervalX_const_filter_complex( dest, prng, min, max, n, temp_array, acceptance_func, ... ) __rnd_filter_interval_complex( int, MT_randomT_intervalX_const, (dest), prng, (min), (max), (n), (temp_array), acceptance_func, ##__VA_ARGS__ )

#endif



#ifndef DISABLE_VAR_MACROS
#ifndef DISABLE_DOUBLES
/**
 * \internal
 * The following methods are created here:
 *     inline double MT_exp_distr_double[T][_fast]( MT_PRNG );
 */
__rnd_exp_distr_double_sync( MT, );
__rnd_exp_distr_double_sync( MT, T );

__box_muller_double( MT, );
__box_muller_double( MT, T );

#if ((defined ZIGGURAT_NORMAL) || (defined ZIGGURAT_NORMAL_DOUBLE))
	__ziggurat_normal_double( MT, );
	__ziggurat_normal_double( MT, T );
#endif
#endif


/**
 * \internal
 * The following methods are created here:
 *     inline float MT_exp_distr_float[T]( MT_PRNG );
 */
__rnd_exp_distr_float_sync( MT, );
__rnd_exp_distr_float_sync( MT, T );

__box_muller_float( MT, );
__box_muller_float( MT, T );
__box_muller_float_native( MT, );
__box_muller_float_native( MT, T );


#if ((defined ZIGGURAT_NORMAL) || (defined ZIGGURAT_NORMAL_FLOAT))
	__ziggurat_normal_float( MT, );
	__ziggurat_normal_float( MT, T );
#endif
#endif


#endif