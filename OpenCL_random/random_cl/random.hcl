#ifndef __RANDOM_HCL
#define __RANDOM_HCL


/**
 * @file random.hcl
 * 
 * @brief This header file defines all commonly used functions and macros
 * 
 * @author Philipp Otterbein
 */


#include "../shared/shared_consts.h"


#ifdef DOXYGEN
	/**
	 * This constant equals the number of work-items in a work-group, if this number was specified in the call of {@link CL_create_compile_string} before compilation of the OpenCL program. Otherwise the constant is undefined.
	 **/ 
	#define __RND_WORKGROUP_SIZE
#endif


#if ( (defined __RND_WORKGROUP_SIZE) && __RND_WORKGROUP_SIZE == 1 )
#ifndef __RND_ATOMIC
	#define __RND_ATOMIC
#endif
#endif


/**
 * This internally used function has the effect of a barrier, but the barrier may be removed when synchronization issues can be excluded
 */
inline void __rnd_barrier( uint flags )
{
#ifdef __RND_ATOMIC
	mem_fence( flags );
#else
	barrier( flags );
#endif
	return;
}


/**
 * This is an internally used function which returns the local-id of a work-item by mapping the multi-dimensional local-id to a one dimensional. This works for work_dim <= 3.
 * @return scalar local-id
 */
inline uint __rnd_get_local_id(void)
{
#if ( !(defined __RND_WORKGROUP_SIZE) || __RND_WORKGROUP_SIZE != 1 )
	return get_local_id(0) + get_local_id(1)*get_local_size(0) + get_local_id(2)*get_local_size(0)*get_local_size(1);
#else
	return 0;
#endif
}


/**
 * This is an internally used function which returns the group-id of a work-group by mapping the multi-dimensional group-id of a work-group to a one-dimensional. This works for work_dim <= 3.
 * @return scalar group-id
 */
inline uint __rnd_get_group_id(void)
{
	return get_group_id(0) + get_group_id(1)*get_num_groups(0) + get_group_id(2)*get_num_groups(0)*get_num_groups(1);
}


/**
 * This is an internally used function which returns the work-group size or local work size by considering the local work size in each dimension. This works for work_dim <= 3.
 * @return scalar work-group size
 */
inline uint __rnd_get_workgroup_size(void)
{
#ifndef __RND_WORKGROUP_SIZE
	return get_local_size(0) * get_local_size(1) * get_local_size(2);
#else
	return __RND_WORKGROUP_SIZE;
#endif
}


/**
 * \internal
 * This is an internally used function which does some santity checks on random number generators
 */
inline bool __rnd_value_check( __global uint* const state, uint prng_id, uint max_local_size )
{
#ifdef RND_DEBUG
	bool error = (state[1] != prng_id);
	if( error )
	{
		if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
			printf( (__constant char*) "The type of the requested generator does not match the generator initialized by the C-program\n" );
		return true;
	}
	bool tmp = (__rnd_get_workgroup_size() > max_local_size);
	error |= tmp;
	if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
		if( tmp )
			printf( (__constant char*) "The number of work-items in a work-group is greater than the number of %lu work-items per work-group the generator supports\n", max_local_size );
	if( prng_id < __PER_WORKITEM_IDS )
	{
		if( state[2] < get_num_groups(0) * get_num_groups(1) * get_num_groups(2) )
		{
			error = true;
			if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
				printf( (__constant char*) "The number of used work-groups is greater than the number of %lu generators initialized by the C-program\n", state[2] );
		}
		else if( state[2] > get_num_groups(0) * get_num_groups(1) * get_num_groups(2) )
			if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
				printf( (__constant char*) "Warning: The number of used work-groups is less than the number of %lu generators initialized by the C-program\n", state[2] );
	}
	else if( state[2] < get_global_size(0) * get_global_size(1) * get_global_size(2) )
	{
		error = true;
		if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
			printf( (__constant char*) "The global work-size is greater than the number of %lu generators initialized by the C-program\n", state[2] );
	}
	else if( state[2] > get_global_size(0) * get_global_size(1) * get_global_size(2) ) 
		if( (get_global_id(0) == 0) & (get_global_id(1) == 0) & (get_global_id(2) == 0) )
			printf( (__constant char*) "Warning: The global work-size is less than the number of %lu generators initialized by the C-program\n", state[2] );

	return error;
#else
	return false;
#endif
}


/**
 * \internal
 * This is an internally used macro which provides a function for getting a uniformly distributed random float in the interval [0,1) or [-1,1) with a PRNG named \b PRNG where the state is private to a work-item.
 *
 * <PRNG>_rndFloat[T]
 * @param prng the PRNG object to use
 * @return random float in the interval [0,1)
 * 
 * <PRNG>_srndFloat[T]
 * @param prng the PRNG object to use
 * @return random float in the interval [-1,1)
 */
#define __rnd_float( PRNG, T ) \
/** returns a uniformly distributed random float in the interval [0,1) by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random float in the interval [0,1) */ \
inline float PRNG##_rndFloat##T( PRNG##_PRNG prng ) \
{ \
	uint h = PRNG##_random##T( prng ); \
	h >>= 9; \
	h |= 0x3f800000; \
	return as_float( h ) - 1.f; \
} \
\
/** returns a uniformly distributed random float in the interval [-1,1) by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random float in the interval [-1,1) */ \
inline float PRNG##_srndFloat##T( PRNG##_PRNG prng ) \
{ \
	uint h = PRNG##_random##T( prng ); \
	h >>= 9; \
	h |= 0x40000000; \
	return as_float( h ) - 3.f; \
}


/**
 * \internal
 * This is an internally used macro which provides functions for getting a uniformly distributed random float with a PRNG named \b PRNG where the state is not private to a work-item.
 *
 * __<PRNG>_rndFloat[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random float in the interval [0,1)
 * 
 *  __<PRNG>_srndFloat[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random float in the interval [-1,1)
 */
#define __rnd_float_sync( PRNG, T ) \
/** \private */ \
inline float __##PRNG##_rndFloat##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint h = __##PRNG##_random##T( prng, sync ); \
	h >>= 9; \
	h |= 0x3f800000; \
	return as_float( h ) - 1.f; \
} \
\
/** returns a uniformly distributed random float in the interval [0,1) by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random float in the interval [0,1) */ \
inline float PRNG##_rndFloat##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_rndFloat##T( prng, false ); \
} \
\
/** \private */ \
inline float __##PRNG##_srndFloat##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint h = __##PRNG##_random##T( prng, sync ); \
	h >>= 9; \
	h |= 0x40000000; \
	return as_float( h ) - 3.f; \
} \
\
/** returns a uniformly distributed random float in the interval [-1,1) by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random float in the interval [-1,1) */ \
inline float PRNG##_srndFloat##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_srndFloat##T( prng, false ); \
}


/**
 * \internal
 * This is an internally used macro which provides a function for getting a uniformly distributed random double with 32 random bits in the mantissa with a PRNG named \b PRNG where the state is private to a work-item
 * 
 * <PRNG>_rndDouble32[T]
 * @param prng the PRNG object to use
 * @return random double in the interval [0,1)
 * 
 * <PRNG>_srndDouble32[T]
 * @param prng the PRNG object to use
 * @return random double in the interval [-1,1)
 */
#define __rnd_double32( PRNG, T ) \
/** returns a uniformly distributed random double in the interval [0,1) with 32bit random mantissa by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [0,1) */ \
inline double PRNG##_rndDouble32##T( PRNG##_PRNG prng ) \
{ \
	ulong h = PRNG##_random##T( prng ); \
	h <<= 20; \
	h |= 0x3ff0000000000000L; \
	return as_double( h ) - 1.; \
} \
\
/** returns a uniformly distributed random double in the interval [-1,1) with 32bit random mantissa by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [-1,1) */ \
inline double PRNG##_srndDouble32##T( PRNG##_PRNG prng ) \
{ \
	ulong h = PRNG##_random##T( prng ); \
	h <<= 20; \
	h |= 0x4000000000000000L; \
	return as_double( h ) - 3.; \
}

/**
 * \internal
 * This is an internally used macro which provides functions for getting a uniformly distributed random double with 32 random bits in the mantissa with a PRNG named \b PRNG where the state is NOT private to a work-item
 * 
 * __<PRNG>_rndDouble32[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random double in the interval [0,1)
 * 
 *  __<PRNG>_srndDouble32[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random double in the interval [-1,1)
 */
#define __rnd_double32_sync( PRNG, T ) \
/** \private */ \
inline double __##PRNG##_rndDouble32##T( PRNG##_PRNG prng, bool sync ) \
{ \
	ulong h = __##PRNG##_random##T( prng, sync ); \
	h <<= 20; \
	h |= 0x3ff0000000000000L; \
	return as_double( h ) - 1.; \
} \
\
/** returns a uniformly distributed random double in the interval [0,1) with 32bit random mantissa by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [0,1) */ \
inline double PRNG##_rndDouble32##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_rndDouble32##T( prng, false ); \
} \
\
/** \private */ \
inline double __##PRNG##_srndDouble32##T( PRNG##_PRNG prng, bool sync ) \
{ \
	ulong h = __##PRNG##_random##T( prng, sync ); \
	h <<= 20; \
	h |= 0x4000000000000000L; \
	return as_double( h ) - 3.; \
} \
\
/** returns a uniformly distributed random double in the interval [-1,1) with 32bit random mantissa by using {@link PRNG##_random##T} for random number generation \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [-1,1) */ \
inline double PRNG##_srndDouble32##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_srndDouble32##T( prng, false ); \
}



/**
 * \internal
 * This is an internally used macro which provides functions for getting a uniformly distributed random double with 52 random bits in the mantissa by concatenating two 32bit numbers generated with a PRNG named \b PRNG where the state is private to a work-item.
 * 
 * <PRNG>_rndDouble[T]
 * @param prng the PRNG object to use
 * @return random double in the interval [0,1)
 * 
 * <PRNG>_srndDouble[T]
 * @param prng the PRNG object to use
 * @return random double in the interval [-1,1)
 */
#define __rnd_double( PRNG, T ) \
/** returns a uniformly distributed random double in the interval [0,1) with 52bit random mantissa by concatenating two 32bit integers generated by{@link PRNG##_random##T} \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [0,1) */ \
inline double PRNG##_rndDouble##T( PRNG##_PRNG prng ) \
{ \
	uint rnd1 = PRNG##_random##T( prng ); \
	rnd1 >>= 12; \
	rnd1 |= 0x3ff00000; \
	uint rnd2 = PRNG##_random##T( prng ); \
	return as_double( ((ulong) rnd1 << 32) | rnd2 ) - 1.; \
} \
\
/** returns a uniformly distributed random double in the interval [-1,1) with 52bit random mantissa by concatenating two 32bit integers generated by {@link PRNG##_random##T} \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [-1,1) */ \
inline double PRNG##_srndDouble##T( PRNG##_PRNG prng ) \
{ \
	uint rnd1 = PRNG##_random##T( prng ); \
	rnd1 >>= 12; \
	rnd1 |= 0x40000000; \
	uint rnd2 = PRNG##_random##T( prng ); \
	return as_double( ((ulong) rnd1 << 32) | rnd2 ) - 3.; \
} 


/**
 * \internal
 * This is an internally used macro which provides functions for getting a random double with 52 random bits in the mantissa by concatenating two 32bit integers generated with a PRNG named \b PRNG where the state is NOT private to a work-item.
 * 
 * __<PRNG>_rndDouble[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random double in the interval [0,1)
 * 
 *  __<PRNG>_srndDouble[T]
 * @param prng the PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return random double in the interval [-1,1)
 */
#define __rnd_double_sync( PRNG, T ) \
/** \private */ \
inline double __##PRNG##_rndDouble##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd1 = __##PRNG##_random##T( prng, sync ); \
	rnd1 >>= 12; \
	rnd1 |= 0x3ff00000; \
	uint rnd2 = __##PRNG##_random##T( prng, sync ); \
	return as_double( ((ulong) rnd1 << 32) | rnd2 ) - 1.; \
} \
\
/** returns a uniformly distributed random double in the interval [0,1) with 52bit random mantissa by concatenating two 32bit integers generated by {@link PRNG##_random##T} \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [0,1) */ \
inline double PRNG##_rndDouble##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_rndDouble##T( prng, false ); \
} \
\
/** \private */ \
inline double __##PRNG##_srndDouble##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd1 = __##PRNG##_random##T( prng, sync ); \
	rnd1 >>= 12; \
	rnd1 |= 0x40000000; \
	uint rnd2 = __##PRNG##_random##T( prng, sync ); \
	return as_double( ((ulong) rnd1 << 32) | rnd2 ) - 3.; \
} \
\
/** returns a uniformly distributed random double in the interval [-1,1) with 52bit random mantissa by concatenating two 32bit integers generated by {@link PRNG##_random##T} \n @param prng PRNG##_PRNG object to use for random number generation \n @return uniformly distributed random double in the interval [-1,1) */ \
inline double PRNG##_srndDouble##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_srndDouble##T( prng, false ); \
}



/**
 * \internal
 * This macro provides a function which returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max}. The relative frequency of different outcomes may be different, but this bias can be neglected when (\b max - \b min) is small and is zero when (\b max - \b min + 1) is a power of two. It is not checked whether \b max >= \b min.
 * 
 * <PRNG>_random[T]_interval
 * @param prng the PRNG object to use for random number generation
 * @param[in] min lower bound of the returned integer
 * @param[in] max upper bound of the returned integer
 * @return random integer in the range \b min, \b min + 1, ..., \b max
 */ 
#define __rnd_int_interval( PRNG, T ) \
/** This function returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} by doing a call to {@link PRNG##_random##T}. The relative frequency of different outcomes may be different, but this bias can be neglected when (\b max - \b min) is small and is zero when (\b max - \b min + 1) is a power of two. It is not checked whether \b max >= \b min. \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the returned integer \n @param[in] max upper bound of the returned integer \n @return random integer in the range \b min, \b min + 1, ..., \b max */ \
inline int PRNG##_random##T##_interval( PRNG##_PRNG prng, int min, int max ) \
{ \
	ulong tmp = (ulong)PRNG##_random##T( prng ) * ((uint)(max - min) + 1); \
	return (int)(tmp >> 32) + min; \
}


/**
 * \internal
 * This macro provides a function which returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} for PRNGs which state is private to each work-item. The relative frequency of each outcome is the same. It is not checked whether \b max >= \b min.
 * @param PRNG specifies the type of the PRNG to use
 * @param T a void argument means that untempered random numbers shall be generated, when the argument is 'T' tempered random numbers are generated
 * 
 * <PRNG>_random[T]_intervalX
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of the random number
 * @param[in] max upper bound of the random number
 * @return signed random number in the range \b min, \b min + 1, ..., \b max
 */ 
#define __rnd_int_intervalX( PRNG, T ) \
/** This function returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} by doing a call to {@link PRNG##_random##T}. The relative frequency of each outcome is the same. It is not checked whether \b max >= \b min. \n @param prng PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random number \n @param[in] max upper bound of the random number \n @return signed random number in the range \b min, \b min + 1, ..., \b max */ \
inline int PRNG##_random##T##_intervalX( PRNG##_PRNG prng, int min, int max ) \
{ \
	uint interval = (uint)((max) - (min)) + 1; \
	uint range = (((ulong)1 << 32) / interval) * interval - 1; \
	ulong rnd; \
	do { \
		rnd = (ulong) PRNG##_random##T( prng ) * interval; \
	} while( (uint)rnd > range ); \
	return (int)(rnd >> 32) + (min); \
}

/**
 * \internal
 * This macro provides a function which returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} for PRNGs which state is NOT private to each work-item. The relative frequency of each outcome is the same. It is not checked whether \b max >= \b min.
 * @param PRNG specifies the type of the PRNG to use
 * @param T a void argument means that untempered random numbers shall be generated, when the argument is 'T' tempered random numbers are generated
 * 
 * <PRNG>_random[T]_intervalX
 * @param prng PRNG object to use for random number generation
 * @param[in] min lower bound of the random number
 * @param[in] max upper bound of the random number
 * @return signed random number in the range \b min, \b min + 1, ..., \b max
 */ 
#define __rnd_int_intervalX_sync( PRNG, T ) \
/** This functions returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} by doing a call to {@link PRNG##_random##T}. The relative frequency of each outcome is the same. It is not checked whether \b max >= \b min. \n @param prng PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random number \n @param[in] max upper bound of the random number \n @return signed random number in the range \b min, \b min + 1, ..., \b max */ \
inline int PRNG##_random##T##_intervalX( PRNG##_PRNG prng, int min, int max ) \
{ \
	uint interval = (uint)((max) - (min)) + 1; \
	uint range = (((ulong)1 << 32) / interval) * interval - 1; \
	bool valid = false; \
	ulong rnd; \
	do { \
		ulong rnd_tmp = (ulong) __##PRNG##_random##T( prng, true ) * interval; \
		if( ((uint)rnd_tmp <= range) & !valid ) \
		{ \
			rnd = rnd_tmp; \
			valid = true; \
		} \
		if( !valid ) \
			prng.sync[1] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[1] ); \
	return (int)(rnd >> 32) + (min); \
}


/**
 * \internal
 * This macro provides a function which returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} for PRNGs which state is private to each work-item. The relative frequency of each outcome is the same and \b min and \b max have to be known at compile-time or the compiler has to know that this values are used several times. It is not checked whether \b max >= \b min.
 * @param PRNG specifies the type of the PRNG to use
 * @param T a void argument means that untempered random numbers shall be generated, when the argument is 'T' tempered random numbers are generated
 * 
 * <PRNG>_random[T]_intervalX_const
 * @param prng PRNG object to use for random number generation
 * @param[in] min compile-time constant lower bound of the random number
 * @param[in] max compile-time constant upper bound of the random number
 * @return signed random number in the range \b min, \b min + 1, ..., \b max
 */ 
#define __rnd_int_intervalX_const( PRNG, T )\
/** This function returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} by doing a call to {@link PRNG##_random##T}. The relative frequency of each outcome is the same and \b min and \b max have to be known at compile-time or the compiler has to know that this values are used several times. It is not checked whether \b max >= \b min. \n @param prng PRNG##_PRNG object to use for random number generation \n @param[in] min compile-time constant lower bound of the random number \n @param[in] max compile-time constant upper bound of the random number \n @return signed random number in the range \b min, \b min + 1, ..., \b max */ \
inline int PRNG##_random##T##_intervalX_const( PRNG##_PRNG prng, int min, int max ) \
{ \
	uint interval = (uint)((max) - (min)) + 1; \
	ulong tmp = ((ulong)1 << 32) / interval; \
	ulong Idiv = ((ulong)1 << 32) / tmp; \
	uint range = tmp * interval - 1; \
	uint rnd; \
	do { \
		rnd = PRNG##_random##T( prng ); \
	} while( rnd > range ); \
	return ((Idiv * rnd) >> 32) + (min); \
}

/**
 * \internal
 * This macro provides a function which returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} for PRNGs which state is NOT private to each work-item. The relative frequency of each outcome is the same and \b min and \b max have to be known at compile-time or the compiler has to know that this values are used several times. It is not checked whether \b max >= \b min.
 * @param PRNG specifies the type of the PRNG to use
 * @param T a void argument means that untempered random numbers shall be generated, when the argument is 'T' tempered random numbers are generated
 * 
 * <PRNG>_random[T]_intervalX_const
 * @param prng PRNG object to use for random number generation
 * @param[in] min compile-time constant lower bound of the random number
 * @param[in] max compile-time constant upper bound of the random number
 * @return signed random number in the range \b min, \b min + 1, ..., \b max
 */ 
#define __rnd_int_intervalX_const_sync( PRNG, T )\
/** This function returns a uniformly distributed signed random 32bit-integer out of {\b min, \b min + 1, ..., \b max} by doing a call to {@link PRNG##_random##T}. The relative frequency of each outcome is the same and \b min and \b max have to be known at compile-time or the compiler has to know that this values are used several times. It is not checked whether \b max >= \b min. \n @param prng PRNG##_PRNG object to use for random number generation \n @param[in] min compile-time constant lower bound of the random number \n @param[in] max compile-time constant upper bound of the random number \n @return signed random number in the range \b min, \b min + 1, ..., \b max */ \
inline int PRNG##_random##T##_intervalX_const( PRNG##_PRNG prng, int min, int max ) \
{ \
	uint interval = (uint)((max) - (min)) + 1; \
	ulong tmp = ((ulong)1 << 32) / interval; \
	ulong Idiv = ((ulong)1 << 32) / tmp; \
	uint range = tmp * interval - 1; \
	uint rnd; \
	bool valid = false; \
	do { \
		uint rnd_tmp = __##PRNG##_random##T( prng, true ); \
		if( ((uint)rnd_tmp <= range) & !valid ) \
		{ \
			rnd = rnd_tmp; \
			valid = true; \
		} \
		if( !valid ) \
			prng.sync[1] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[1] ); \
	return ((Idiv * rnd) >> 32) + (min); \
}



#ifndef DISABLE_VAR_MACROS
/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is NOT private to a work-item. Used in cases where \b prng_method has only one argument
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest The accepted random number is returned in the location where \b dest points to
 * @param prng PRNG object to use for random number generation
 * @param acceptance_func this method decides whether a random number is accepted. It has signature 'bool <name>( \b type, ...)'. The first argument of \b acceptance_func is the random number to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection_sync( type, prng_method, dest, prng, acceptance_func, ... ) \
do { \
	bool valid = false; \
	do { \
		type __tmp_##prng_method = __##prng_method( prng, true ); \
		bool accepted = acceptance_func( __tmp_##prng_method, ##__VA_ARGS__ ); \
		if( accepted & !valid ) \
		{ \
			*(dest) = __tmp_##prng_method; \
			valid = true; \
		} \
		if( !valid ) \
			prng.sync[1] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[1] ); \
} while(0)

/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is private to a work-item. Used in cases where \b prng_method has only one argument
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest The accepted random number is returned in the location where \b dest points to
 * @param prng PRNG object to use for random number generation
 * @param acceptance_func this method decides whether a random number is accepted. It has signature 'bool <name>( \b type, ...)'. The first argument of \b acceptance_func is the random number to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection( type, prng_method, dest, prng, acceptance_func, ... ) \
do { \
	type __tmp_##prng_method; \
	do { \
		__tmp_##prng_method = prng_method( prng ); \
	} while( !acceptance_func( __tmp_##prng_method, ##__VA_ARGS__ ) ); \
	*(dest) = __tmp_##prng_method; \
} while(0)


/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is NOT private to a work-item. Used in cases where \b prng_method has three arguments
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest The accepted random number is returned in the location where \b dest points to
 * @param prng PRNG object to use for random number generation
 * @param min second argument of \b prng_method
 * @param max third argument of \b prng_method
 * @param acceptance_func this method decides whether a random number is accepted. It has signature 'bool <name>( \b type, ...)'. The first argument of \b acceptance_func is the random number to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection_interval_sync( type, prng_method, dest, prng, min, max, acceptance_func, ... ) \
do { \
	bool valid = false; \
	do { \
		type __tmp_##prng_method = prng_method( prng, min, max ); \
		mem_fence( CLK_LOCAL_MEM_FENCE ); \
		prng.sync[2] = 1; \
		bool accepted = acceptance_func( __tmp_##prng_method, ##__VA_ARGS__ ); \
		if( accepted & !valid ) \
		{ \
			*(dest) = __tmp_##prng_method; \
			valid = true; \
		} \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		if( !valid ) \
			prng.sync[2] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[2] ); \
} while(0)

/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is private to a work-item. Used in cases where \b prng_method has three arguments
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest The accepted random number is returned in the location where \b dest points to
 * @param prng PRNG object to use for random number generation
 * @param min second argument of \b prng_method
 * @param max third argument of \b prng_method
 * @param acceptance_func this method decides whether a random number is accepted. It has signature 'bool <name>( \b type, ...)'. The first argument of \b acceptance_func is the random number to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection_interval( type, prng_method, dest, prng, min, max, acceptance_func, ... ) \
do { \
	type __tmp_##prng_method; \
	do { \
		__tmp_##prng_method = prng_method( prng, min, max ); \
	} while( !acceptance_func( __tmp_##prng_method, ##__VA_ARGS__ ) ); \
	*(dest) = __tmp_##prng_method; \
} while(0)



/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is NOT private to a work-item. It is useful when the return value can be easily computed in the acceptance condition. Used in cases where \b prng_method has only one argument
 * @param type return type of prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest pointer to memory location. The result is written to the location where dest points to
 * @param prng PRNG object to use for random number generation, first argument of \b prng_method
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param acceptance_func this method decides whether a random number is accepted and it decides which value is returned in \b dest. It has signature 'bool <name>( __private typeof(\b dest), const \b type *const, ...)'. \b acceptance_func has to write accepted values to its first argument. The second argument of \b acceptance_func is the array of \b n random numbers to be checked.
 * @param ... this optional arguments are redirected to the acceptance method
 */
#define __rnd_rejection_complex_sync( type, prng_method, dest, prng, n, acceptance_func, ... ) \
do { \
	bool valid = false; \
	do { \
		type __rnd_tmp_##prng_method[n]; \
		for( int i = 0; i < (n); i++ ) \
			__rnd_tmp_##prng_method[i] = __##prng_method( prng, true ); \
		if( !valid ) \
		{ \
			typeof(*(dest)) __rejection_##prng_method; \
			bool accepted = acceptance_func( &__rejection_##prng_method, __rnd_tmp_##prng_method, ##__VA_ARGS__ ); \
			valid |= accepted; \
			if( accepted ) \
				*(dest) = __rejection_##prng_method; \
		} \
		if( !valid ) \
			prng.sync[1] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[1] ); \
} while(0)

/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is private to a work-item. It is useful when the return value can be easily computed in the acceptance condition. Used in cases where \b prng_method has only one argument
 * @param type return type of prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest pointer to memory location. The result is written to the location where dest points to
 * @param prng PRNG object to use for random number generation, first argument of \b prng_method
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param acceptance_func this method decides whether a random number is accepted and it decides which value is returned in \b dest. It has signature 'bool <name>( __private typeof(\b dest), const \b type *const, ...)'. \b acceptance_func has to write accepted values to its first argument. The second argument of \b acceptance_func is the array of \b n random numbers to be checked..
 * @param ... this optional arguments are redirected to the acceptance method
 */
#define __rnd_rejection_complex( type, prng_method, dest, prng, n, acceptance_func, ... ) \
do { \
	type __rnd_tmp_##prng_method[n]; \
	typeof(*(dest)) __tmp_##prng_method; \
	do { \
		for( int i = 0; i < (n); i++ ) \
			__rnd_tmp_##prng_method[i] = prng_method( prng ); \
	} while( !acceptance_func( &__tmp_##prng_method, __rnd_tmp_##prng_method, ##__VA_ARGS__ ) ); \
	*(dest) = __tmp_##prng_method; \
} while(0)

/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is NOT private to a work-item. It is useful when the return value can be easily computed in the acceptance condition. Used in cases where \b prng_method has three arguments
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest pointer to memory location. The result is written to the location where dest points to
 * @param prng PRNG object to use for random number generation, first argument of \b prng_method
 * @param min second argument of \b prng_method
 * @param max third argument of \b prng_method
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param acceptance_func this method decides whether a random number is accepted and it decides which value is returned in \b dest. It has signature 'bool <name>( __private typeof(\b dest), const \b type *const, ...)'. \b acceptance_func has to write accepted values to its first argument. The second argument of \b acceptance_func is the array of \b n random numbers to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection_interval_complex_sync( type, prng_method, dest, prng, min, max, n, acceptance_func, ... ) \
do { \
	bool valid = false; \
	do { \
		type __rnd_tmp_##prng_method[n]; \
		for( int i = 0; i < (n); i++ ) \
			__rnd_tmp_##prng_method[i] = prng_method( prng, min, max ); \
		mem_fence( CLK_LOCLA_MEM_FENCE ); \
		prng.sync[2] = 1; \
		if( !valid ) \
		{ \
			typeof(*(dest)) __tmp_##prng_method; \
			bool accepted = acceptance_func( &__tmp_##prng_method, __rnd_tmp_##prng_method, ##__VA_ARGS__ ); \
			valid |= accepted; \
			if( accepted ) \
				*(dest) = __tmp_##prng_method; \
		} \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		if( !valid ) \
			prng.sync[2] = 0; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( !prng.sync[2] ); \
} while(0)

/**
 * \private
 * This macro creates code for a rejection loop for a PRNG which state is private to a work-item. It is useful when the return value can be easily computed in the acceptance condition. Used in cases where \b prng_method has three arguments
 * @param type return type of \b prng_method
 * @param prng_method specifies the method which shall be used for random number generation
 * @param[out] dest pointer to memory location. The result is written to the location where dest points to
 * @param prng PRNG object to use for random number generation, first argument of \b prng_method
 * @param min second argument of \b prng_method
 * @param max third argument of \b prng_method
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param acceptance_func this method decides whether a random number is accepted and it decides which value is returned in \b dest. It has signature 'bool <name>( __private typeof(\b dest), const \b type *const, ...)'. \b acceptance_func has to write accepted values to its first argument. The second argument of \b acceptance_func is the array of \b n random numbers to be checked.
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_rejection_interval_complex( type, prng_method, dest, prng, min, max, n, acceptance_func, ... ) \
do { \
	type __rnd_tmp_##prng_method[n]; \
	typeof(*(dest)) __tmp_##prng_method; \
	do { \
		for( int i = 0; i < (n); i++ ) \
			__rnd_tmp_##prng_method[i] = prng_method( prng, min, max ); \
	} while( !acceptance_func( &__tmp_##prng_method, __rnd_tmp_##prng_method, ##__VA_ARGS__ ) ); \
	*(dest) = __tmp_##prng_method; \
} while(0)






/**
 * \private
 * This macro provides code which returns a random number generated by \b prng_method and is accepted by a acceptance method. \b prng_method has to have one argument
 * @param prng_method method used for random number generation
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a random number or not. It has the signature 'bool \b acceptance_func( return type of \b prng_method, ...)' and its first argument is the random number generated by \b prng_method
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_filter( prng_method, dest, prng, temp_array, acceptance_func, ... ) \
do { \
	__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	prng.sync[2] = 0; \
	do { \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		typeof(*(dest)) __tmp_##acceptance_func = prng_method( prng ); \
		if( acceptance_func( __tmp_##acceptance_func, ##__VA_ARGS__ ) ) \
			(temp_array)[ atomic_inc(prng.sync + 2) % __rnd_get_workgroup_size() ] = __tmp_##acceptance_func; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( prng.sync[2] < __rnd_get_workgroup_size() - 1 ); \
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE ); /*when temp_array is a pointer to global memory, consistency of global memory within a work-group should be restored*/ \
	*(dest) = (temp_array)[__rnd_get_local_id()]; \
} while(0)


/**
 * \private
 * This macro provides code which returns a random number generated by \b prng_method and is accepted by a acceptance method. \b prng_method has to have three arguments
 * @param prng_method method used for random number generation
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param[in] min second argument of \b prng_method
 * @param[in] max third argument of \b prng_method
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a random number or not. It has the signature 'bool \b acceptance_func( return type of \b prng_method, ...)' and its first argument is the random number generated by \b prng_method
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_filter_interval( prng_method, dest, prng, min, max, temp_array, acceptance_func, ... ) \
do { \
	__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	prng.sync[2] = 0; \
	do { \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		typeof(*(temp_array)) __tmp_##acceptance_func = prng_method( prng, min, max ); \
		if( acceptance_func( __tmp_##acceptance_func, ##__VA_ARGS__ ) ) \
			(temp_array)[ atomic_inc(prng.sync + 2) % __rnd_get_workgroup_size() ] = __tmp_##acceptance_func; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( prng.sync[2] < __rnd_get_workgroup_size() - 1 ); \
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE ); /*when temp_array is a pointer to global memory, consistency of global memory within a work-group should be restored*/ \
	*(dest) = (temp_array)[__rnd_get_local_id()]; \
} while(0)



/**
 * \private
 * This macro provides code which returns a result chosen by a acceptance method and derived from a random number generated by \b prng_method. \b prng_method has to have one argument
 * @param return_type return type of \b prng_method
 * @param prng_method method used for random number generation
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a result or not. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const \b return_type *const, ...)' and \b acceptance_func has to write its results to the first argument. The second argument is the array of \b n random numbers generated by \b prng_method
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_filter_complex( return_type, prng_method, dest, prng, n, temp_array, acceptance_func, ... ) \
do { \
	__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	prng.sync[2] = 0; \
	do { \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		typeof(*(temp_array)) __tmp_##acceptance_func; \
		return_type __rnd_##acceptance_func[n]; \
		for( int i = 0; i < (n); i++ ) \
			__rnd_##acceptance_func[i] = prng_method( prng ); \
		if( acceptance_func( &__tmp_##acceptance_func, __rnd_##acceptance_func, ##__VA_ARGS__ ) ) \
			(temp_array)[ atomic_inc(prng.sync + 2) % __rnd_get_workgroup_size() ] = __tmp_##acceptance_func; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( prng.sync[2] < __rnd_get_workgroup_size() - 1 ); \
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE ); /*when temp_array is a pointer to global memory, consistency of global memory within a work-group should be restored*/ \
	*(dest) = (temp_array)[__rnd_get_local_id()]; \
} while(0)


/**
 * \private
 * This macro provides code which returns a result chosen by a acceptance method and derived from a random number generated by \b prng_method. \b prng_method has to have three arguments
 * @param return_type return type of \b prng_method
 * @param prng_method method used for random number generation
 * @param[out] dest pointer to memory location, result is returned in \b dest
 * @param prng PRNG object to use for random number generation
 * @param min second argument of \b prng_method
 * @param max third argument of \b prng_method
 * @param n compile-time constant, number of random numbers to generate as input for \b acceptance_func. 
 * @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array
 * @param acceptance_func acceptance method wich decides whether to accept a result or not. It has the signature 'bool \b acceptance_func( __private typeof(\b dest), const \b return_type *const, ...)' and \b acceptance_func has to write its results to the first argument. The second argument is the array of \b n random numbers generated by \b prng_method
 * @param ... this optional arguments are redirected to \b acceptance_func
 */
#define __rnd_filter_interval_complex( return_type, prng_method, dest, prng, min, max, n, temp_array, acceptance_func, ... ) \
do { \
	__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	prng.sync[2] = 0; \
	do { \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
		typeof(*(temp_array)) __tmp_##acceptance_func; \
		return_type __rnd_##acceptance_func[n]; \
		for( int i = 0; i < (n); i++ ) \
			__rnd_##acceptance_func[i] = prng_method( prng, min, max ); \
		if( acceptance_func( &__tmp_##acceptance_func, __rnd_##acceptance_func, ##__VA_ARGS__ ) ) \
			(temp_array)[ atomic_inc(prng.sync + 2) % __rnd_get_workgroup_size() ] = __tmp_##acceptance_func; \
		__rnd_barrier( CLK_LOCAL_MEM_FENCE ); \
	} while( prng.sync[2] < __rnd_get_workgroup_size() - 1 ); \
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE ); /*when temp_array is a pointer to global memory, consistency of global memory within a work-group should be restored*/ \
	*(dest) = (temp_array)[__rnd_get_local_id()]; \
} while(0)

#endif


/**
 * \internal
 * This is an internally used function which copies the state of a group of PRNGs from global memory to local memory and initializes the generators
 * @param[out] state_dest pointer to local memory where a PRNG is copied to
 * @param[in] global_state pointer to global memory where the internally states of several PRNGs are saved
 * @param[out] pos pointer to private memory. points to a memory location where the position in the PRNG-stream of a work-item is saved
 * @param[in] size size of the state of a single PRNG stream
 */
inline void __rnd_load_state( __local uint* state_dest, __global uint* global_state, __private uint* pos, const uint size )
{
	uint local_id = __rnd_get_local_id();
	uint group_id = __rnd_get_group_id();
	
	if( local_id == 0 )
		global_state[0] = __rnd_get_workgroup_size();
	*pos = local_id + global_state[group_id * (size+1) + size + __OFFSET];
	*pos -= (*pos >= size)*size;
	
	event_t event = async_work_group_copy( state_dest, global_state + group_id * (size+1) + __OFFSET, size, 0 );
	wait_group_events( 1, &event );
	barrier( CLK_GLOBAL_MEM_FENCE );
}


/**
 * \internal
 * This is an internally used function which copies the state of a group of PRNGs after their usage from local memory back to global memory
 * @param[out] global_state pointer to global memory where the states of several PRNGs are copied to
 * @param[in] local_state pointer to local memory where a state of a PRNG is saved
 * @param[out] pos position of a work-item in the stream of a single PRNG
 * @param[in] size size of the the state of a single PRNG stream
 */
inline void __rnd_save_state( __global uint* global_state, const __local uint* local_state, const uint pos, const uint size  )
{
	uint local_id = __rnd_get_local_id();
	uint group_id = __rnd_get_group_id();
	
	barrier( CLK_LOCAL_MEM_FENCE );
	if( local_id == 0 )
		global_state[group_id * (size+1) + size + __OFFSET] = pos;
	event_t event = async_work_group_copy( global_state + group_id*(size+1) + __OFFSET, local_state, size, 0 );
	wait_group_events( 1, &event );
	barrier( CLK_GLOBAL_MEM_FENCE );
}


/**
 * \internal
 * This function used by __rnd_exp_distr_* checks whether a random number equals zero and counts the leading zeroes
 */
bool __check_int_for_zero( uint rnd, uint *leading_zeroes )
{
	*leading_zeroes += clz(rnd);
	return (rnd != 0);
}


/**
 * \internal
 * This macro provides code for a function which generates random doubles from a exponential probability distribution p(x) = exp(-x)
 * 
 * <PRNG>_exp_distr_double[T]_fast returns an exponentially distributed double which may contain with a probability of 2^-12 less than 52 random bits in the mantissa. The mantissa contains at least 36 random bits.
 * <PRNG>_exp_distr_double[T] returns an exponentially distributed double where all bits in the mantissa are random
 */
#define __rnd_exp_distr_double( PRNG, T ) \
/** PRNG##_exp_distr_double##T##_fast returns an exponentially distributed double which may contain with a probability of 2^-12 less than 52 random bits in the mantissa. The mantissa contains at least 36 random bits. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline double PRNG##_exp_distr_double##T##_fast( PRNG##_PRNG prng ) \
{ \
	uint rnd1, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd1, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = PRNG##_random##T( prng ); \
	ulong rnd = ((ulong)rnd1 << 32) | rnd2; \
	return M_LN2 * (64 + (leading_zeroes & ~31)) - log((double)rnd); \
} \
\
/** PRNG##_exp_distr_double##T returns an exponentially distributed double. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline double PRNG##_exp_distr_double##T( PRNG##_PRNG prng ) \
{ \
	uint rnd1, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd1, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = PRNG##_random##T( prng ); \
	uint rnd3 = PRNG##_random##T( prng ); \
	ulong rnd = ((ulong)rnd1 << 32) | rnd2; \
	rnd <<= leading_zeroes % 32; \
	rnd3 >>= 32 - (leading_zeroes % 32); \
	rnd |= ((leading_zeroes % 32) != 0) * rnd3; \
	return M_LN2 * (64 + leading_zeroes) - log((double)rnd); \
}


#define __rnd_exp_distr_double_sync( PRNG, T ) \
/** \private */ \
inline double __##PRNG##_exp_distr_double##T##_fast( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd1, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd1, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = __##PRNG##_random##T( prng, sync ); \
	ulong rnd = ((ulong)rnd1 << 32) | rnd2; \
	return M_LN2 * (64 + (leading_zeroes & ~31)) - log((double)rnd); \
} \
\
/** PRNG##_exp_distr_double##T##_fast returns an exponentially distributed double which may contain with a probability of 2^-12 less than 52 random bits in the mantissa. The mantissa contains at least 36 random bits. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline double PRNG##_exp_distr_double##T##_fast( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_exp_distr_double##T##_fast( prng, false ); \
} \
\
/** \private */ \
inline double __##PRNG##_exp_distr_double##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd1, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd1, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = PRNG##_random##T( prng ); \
	uint rnd3 = __##PRNG##_random##T( prng, sync ); \
	ulong rnd = ((ulong)rnd1 << 32) | rnd2; \
	rnd <<= leading_zeroes % 32; \
	rnd3 >>= 32 - (leading_zeroes % 32); \
	rnd |= ((leading_zeroes % 32) != 0) * rnd3; \
	return M_LN2 * (64 + leading_zeroes) - log((double)rnd); \
} \
\
/** PRNG##_exp_distr_double##T returns an exponentially distributed double. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline double PRNG##_exp_distr_double##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_exp_distr_double##T( prng, false ); \
}


/**
 * \internal
 * This macro provides code for a function which generates random floats from a exponential probability distribution p(x) = exp(-x)
 * 
 * <PRNG>_exp_distr_float[T]_native returns an exponentially distributed float, but uses native_log to do so. This is fast, but may be too inaccurate on some hardware
 * <PRNG>_exp_distr_float[T] returns an exponentially distributed float
 */
#define __rnd_exp_distr_float( PRNG, T ) \
/** PRNG##_exp_distr_float##T returns an exponentially distributed float. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline float PRNG##_exp_distr_float##T( PRNG##_PRNG prng ) \
{ \
	uint rnd, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = PRNG##_random##T( prng ); \
	rnd <<= leading_zeroes % 32; \
	rnd2 >>= 32 - (leading_zeroes % 32); \
	rnd |= ((leading_zeroes % 32) != 0) * rnd2; \
	return M_LN2_F * (32 + leading_zeroes) - log((float)rnd); \
} \
\
/** PRNG##_exp_distr_float##T returns an exponentially distributed float, but uses native_log to do so. This is fast, but may be too inaccurate on some hardware. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline float PRNG##_exp_distr_float##T##_native( PRNG##_PRNG prng ) \
{ \
	uint rnd, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = PRNG##_random##T( prng ); \
	rnd <<= leading_zeroes % 32; \
	rnd2 >>= 32 - (leading_zeroes % 32); \
	rnd |= ((leading_zeroes % 32) != 0) * rnd2; \
	return M_LN2_F * (32 + leading_zeroes) - native_log((float)rnd); \
}


#define __rnd_exp_distr_float_sync( PRNG, T ) \
/** \internal */ \
inline float __##PRNG##_exp_distr_float##T( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = __##PRNG##_random##T( prng, sync ); \
	rnd <<= leading_zeroes % 32; \
	rnd2 >>= 32 - (leading_zeroes % 32); \
	rnd |=((leading_zeroes % 32) != 0) * rnd2; \
	return M_LN2_F * (32 + leading_zeroes) - log((float)rnd); \
} \
\
/** PRNG##_exp_distr_float##T returns an exponentially distributed float. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline float PRNG##_exp_distr_float##T( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_exp_distr_float##T( prng, false ); \
} \
\
/** \private */ \
inline float __##PRNG##_exp_distr_float##T##_native( PRNG##_PRNG prng, bool sync ) \
{ \
	uint rnd, leading_zeroes = 0; \
	PRNG##_random##T##_rejection( &rnd, prng, __check_int_for_zero, &leading_zeroes ); \
	uint rnd2 = __##PRNG##_random##T( prng, sync ); \
	rnd <<= leading_zeroes % 32; \
	rnd2 >>= 32 - (leading_zeroes % 32); \
	rnd |= ((leading_zeroes % 32) != 0) * rnd2; \
	return M_LN2_F * (32 + leading_zeroes) - native_log((float)rnd); \
} \
\
/** PRNG##_exp_distr_float##T returns an exponentially distributed float, but uses native_log to do so. This is fast, but may be too inaccurate on some hardware. PDF: f(x) = exp(-x); calls {@link PRNG##_random##T} internally \n @param prng the PRNG##_PRNG object to use for random number generation*/ \
inline float PRNG##_exp_distr_float##T##_native( PRNG##_PRNG prng ) \
{ \
	return __##PRNG##_exp_distr_float##T##_native( prng, false ); \
} \




#ifdef DOXYGEN


#define __rnd_random_rejection_doc(PRNG, T) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for low rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_rejection( <address qualifier> uint *dest, PRNG##_PRNG prng, bool (*acceptance_func)(uint, ...), ... );
	
#define __rnd_rnd_rejection_doc(PRNG, T, type, Type) /** This macro creates uniformly distributed random type##s in the interval [0,1) generated by {@link PRNG##_rnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for low rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_rnd##Type##T##_rejection( <address qualifier> type *dest, PRNG##_PRNG prng, bool (*acceptance_func)(type, ...), ... );
	
#define __rnd_srnd_rejection_doc(PRNG, T, type, Type) /** This macro creates uniformly distributed random type##s in the interval [-1,1) generated {@link PRNG##_srnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for low rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_srnd##Type##T##_rejection( <address qualifier> type *dest, PRNG##_PRNG prng, bool (*acceptance_func)(type, ...), ... );
	
#define __rnd_interval_rejection_doc(PRNG, T, X) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T##_interval##X} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for low rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param[in] max upper bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_interval##X##_rejection( <address qualifier> int *dest, PRNG##_PRNG prng, bool (*acceptance_func)(int, ...), ... );
	
#define __rnd_random_rejection_complex_doc(PRNG, T) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for low rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_rejection_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, bool (*acceptance_func)(__private <type>*, const uint *const, ...), ... );
	
#define __rnd_rnd_rejection_complex_doc(PRNG, T, _type, Type) /** This macro creates uniformly distributed random _type##s in the interval [0,1) generated by {@link PRNG##_rnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for low rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_rnd##Type##T##_rejection_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, bool (*acceptance_func)(__private <type>*, const type *const, ...), ... );
	
#define __rnd_srnd_rejection_complex_doc(PRNG, T, _type, Type) /** This macro creates uniformly distributed random _type##s in the interval [-1,1)  generated by {@link PRNG##_srnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for low rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_srnd##Type##T##_rejection_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, bool (*acceptance_func)(__private <type>*, const type *const, ...), ... );
	
#define __rnd_interval_rejection_complex_doc(PRNG, T, X) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T##_interval##X} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for low rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param[in] max upper bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_interval##X##_rejection_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, bool (*acceptance_func)(__private <type>*, const int *const, ...), ... );



#define __rnd_random_filter_doc(PRNG, T) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for higher rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_filter( <address qualifier> uint *dest, PRNG##_PRNG prng, {__local,__global} uint *temp_array, bool (*acceptance_func)(uint, ...), ... );
	
#define __rnd_rnd_filter_doc(PRNG, T, type, Type) /** This macro creates uniformly distributed random type##s in the interval [0,1) generated by {@link PRNG##_rnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for higher rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_rnd##Type##T##_filter( <address qualifier> type *dest, PRNG##_PRNG prng, {__local,__global} type *temp_array, bool (*acceptance_func)(type, ...), ... );
	
#define __rnd_srnd_filter_doc(PRNG, T, type, Type) /** This macro creates uniformly distributed random type##s in the interval [-1,1) generated by {@link PRNG##_srnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for higher rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_srnd##Type##T##_filter( <address qualifier> type *dest, PRNG##_PRNG prng, {__local,__global} type *temp_array, bool (*acceptance_func)(type, ...), ... );
	
#define __rnd_interval_filter_doc(PRNG, T, X) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T##_interval##X} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. It returns the first accepted number. fast for higher rejection rates \n @param [out] dest the accepted random number is returned in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param[in] max upper bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n  @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides whether a random number is accepted. The first argument of the function is the random number to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_interval##X##_filter( <address qualifier> int *dest, PRNG##_PRNG prng, {__local,__global} int *temp_array, bool (*acceptance_func)(int, ...), ... );
	
#define __rnd_random_filter_complex_doc(PRNG, T) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for higher rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_filter_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, {__local,__global} <type>* temp_array, bool (*acceptance_func)(__private <type>*, const uint *const, ...), ... );
	
#define __rnd_rnd_filter_complex_doc(PRNG, T, _type, Type) /** This macro creates uniformly distributed random _type##s in the interval [0,1) generated by {@link PRNG##_rnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for higher rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_rnd##Type##T##_filter_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, {__local,__global} <type>* temp_array, bool (*acceptance_func)(__private <type>*, const type *const, ...), ... );
	
#define __rnd_srnd_filter_complex_doc(PRNG, T, _type, Type) /** This macro creates uniformly distributed random _type##s in the interval [-1,1) generated by {@link PRNG##_srnd##Type##T} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for higher rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array  \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_srnd##Type##T##_filter_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, {__local,__global} <type>* temp_array, bool (*acceptance_func)(__private <type>*, const type *const, ...), ... );
	
#define __rnd_interval_filter_complex_doc(PRNG, T, X) /** This macro creates uniformly distributed random integers generated by {@link PRNG##_random##T##_interval##X} and checks them with \b acceptance_func until \b acceptance_func evaluates to true. The acceptance function also decides which value is returned. fast for higher rejection rates \n @param [out] dest the acceptance functions returns its result in the location where \b dest points to \n @param prng the PRNG##_PRNG object to use for random number generation \n @param[in] min lower bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param[in] max upper bound of the random integer created by {@link PRNG##_random##T##_interval##X} \n @param [in] n compile-time constant, number of random numbers to generate as input for \b acceptance_func. \n @param[in,out] temp_array array in local or global memory with the number of elements equal to the work-group size. Accepted results are stored in \b temp_array \n @param acceptance_func this is the name of the function which decides when to terminate and which result is returned in its first argument. The second argument of the function is a pointer to the array of random numbers to be checked. \n @param ... this arguments are additional arguments of \b acceptance_func */ \
	PRNG##_random##T##_interval##X##_filter_complex( <address qualifier> <type> *dest, PRNG##_PRNG prng, int n, {__local,__global} <type>* temp_array, bool (*acceptance_func)(__private <type>*, const int *const, ...), ... );

	
#endif


#endif
