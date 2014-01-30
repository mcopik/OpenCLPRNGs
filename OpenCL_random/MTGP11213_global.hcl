#ifndef __MTGP11213_GLOBAL_H
#define __MTGP11213_GLOBAL_H

/**
 * @file MTGP11213_global.hcl
 * 
 * @brief
 * 
 * @author Philipp Otterbein
 */


/**
 * A {@link MTGP11213_state} object points to MTGP11213 PRNG streams in global device memory and is used as kernel argument
 */
typedef __global uint* MTGP11213_state;

/**
 * MTGP11213_PRNG represents a by {@link MTGP11213_init} initialized MTGP11213 PRNG object on device side
 */
typedef struct
{
	MTGP11213_state const __mtgp11213; /**< \private */
	__global uint * const __state; /**< \private */
	/** sync[0] can be used freely by the user */
	__local volatile uint * const sync;
	__private uint * const __pos; /**< \private */
} MTGP11213_PRNG;



inline __global uint *__mtgp11213_init( MTGP11213_state state, __private uint *ptr_pos );


/**
 * This macro creates and initializes an object of type MTGP11213_PRNG named \b prng. It has to be called from a kernel, but the object \b prng may also be used in functions.
 * @param prng the name of the object to be created
 * @param[in] state is a kernel argument of type MTGP11213_state pointing to the state of the PRNGs in global memory
 */
#define MTGP11213_init( prng, state ) \
	uint __mtgp11213_pos_##state; \
	__local volatile uint __mtgp11213_sync_##state[3]; \
	if( __rnd_value_check( state, __MTGP11213_ID, 265 ) ) \
		return; \
	const MTGP11213_PRNG prng = { state, __mtgp11213_init( state, &__mtgp11213_pos_##state ), __mtgp11213_sync_##state, &__mtgp11213_pos_##state }



#include "random_cl/MTGP11213.hcl"


/**
 * \internal
 * This internal function loads the position of a work-item within the state of a PRNG and returns the global address of this state
 * @param[in] state is a kernel argument of type MTGP11213_state pointing to the state of the PRNGs in global memory
 * @param[out] ptr_pos specifies where the position of a work-item within the state of a PRNG is saved
 * @return the global address of the state on which a work-item operates
 */
inline __global uint *__mtgp11213_init( MTGP11213_state state, __private uint *ptr_pos )
{
	uint local_id = __rnd_get_local_id();
#ifndef __RND_WORKGROUP_SIZE
	if( local_id == 0 )
		state[0] = __rnd_get_workgroup_size();
#endif
	uint offset = __rnd_get_group_id() * (__MTGP11213_LENGTH + 1) + __OFFSET;
	uint pos = state[ offset + __MTGP11213_LENGTH ] + local_id;
	pos -= (pos >= __MTGP11213_LENGTH) * __MTGP11213_LENGTH;
	*ptr_pos = pos;
	return state + offset;
}



#define STATE prng.__state
/**
 * \internal
 * This function is an internally used function and provides the functionality of the PRNG
 * @param prng MTGP11213_PRNG object to use for random number generation
 * @return uniformly distributed 32bit random integer
 */
inline uint __MTGP11213_random_wo_barrier( MTGP11213_PRNG prng, const bool sync )
{
	uint pos = *prng.__pos;
	uint h = (STATE[pos] & MASK) ^ STATE[ pos+1 - (pos==__MTGP11213_LENGTH-1)*__MTGP11213_LENGTH ];
	if( sync )
	{
		mem_fence( CLK_LOCAL_MEM_FENCE );
		prng.sync[1] = 1;
		mem_fence( CLK_LOCAL_MEM_FENCE );
	}
	h ^= h << SH1;
	h ^= STATE[ pos+M - (pos >= __MTGP11213_LENGTH-M) * __MTGP11213_LENGTH ] >> SH2;
	h ^= __mtgp11213_tbl[h & 0x0f];
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	STATE[pos] = h;
#ifndef __RND_WORKGROUP_SIZE
	pos += *prng.__mtgp11213;
#else
	pos += __RND_WORKGROUP_SIZE;
#endif
	*prng.__pos = pos - (pos >= __MTGP11213_LENGTH) * __MTGP11213_LENGTH;
	return h;
}
#undef STATE


/**
 * \internal
 * This function creates a uniformly distributed random integer using the MTGP11213_PRNG object \b prng
 * @param prng MTGP11213_PRNG object to use for random number generation
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return 32bit random integer
 */ 
inline uint __MTGP11213_random( MTGP11213_PRNG prng, bool sync )
{
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	return __MTGP11213_random_wo_barrier( prng, sync ); 
}


/**
 * \internal
 * This function creates a tempered, uniformly distributed random integer using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use for random number generation
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return tempered 32bit random integer
 */ 
inline uint __MTGP11213_randomT( MTGP11213_PRNG prng, bool sync )
{
	uint pos = *prng.__pos;
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	uint x = prng.__state[ pos + M-1 + (pos >= __MTGP11213_LENGTH-M+1) * __MTGP11213_LENGTH ];
	x ^= x >> 16;
	x ^= x >> 8;
	x = __mtgp11213_temper_tbl[x & 0x0f];
	uint h = __MTGP11213_random_wo_barrier( prng, sync );
	h ^= x;
	return h;
}


/**
 * \internal
 * This internal function creates tempered, uniformly distributed unsigned random floats using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return tempered random float in the interval [0,1)
 */
inline float __MTGP11213_rndFloatT( MTGP11213_PRNG prng, bool sync )
{
	uint pos = *prng.__pos;
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	uint x = prng.__state[ pos + M-1 + (pos >= __MTGP11213_LENGTH-M+1) * __MTGP11213_LENGTH ];
	x ^= x >> 16;
	x ^= x >> 8;
	x = __mtgp11213_float_temper_tbl[x & 0x0f];
	uint h = __MTGP11213_random_wo_barrier( prng, sync );
	h >>= 9;
	h ^= x;
	return as_float( h ) - 1.f;
}


/**
 * \internal
 * This internal function creates tempered, uniformly distributed signed random floats using the MTGP11213_PRNG object \b prng
 * @param prng PRNG object to use
 * @param sync specifies whether the random number will be used in a conditional statement
 * @return tempered random float in the interval [-1,1)
 */
inline float __MTGP11213_srndFloatT( MTGP11213_PRNG prng, bool sync )
{
	uint pos = *prng.__pos;
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	uint x = prng.__state[ pos + M-1 + (pos >= __MTGP11213_LENGTH-M+1) * __MTGP11213_LENGTH ];
	x ^= x >> 16;
	x ^= x >> 8;
	x = __mtgp11213_float_temper_tbl[x & 0x0f] + 0x8000000;
	uint h = __MTGP11213_random_wo_barrier( prng, sync );
	h >>= 9;
	h ^= x;
	return as_float( h ) - 3.f;
}


/**
 * This function saves the state of an object of type MTGP11213_PRNG to global memory. It has to be called before a kernel, in which the PRNG is called, returns.
 * @param prng the MTGP11213_PRNG object to be saved
 */
inline void MTGP11213_save( MTGP11213_PRNG prng )
{
	if( __rnd_get_local_id() == 0 )
		prng.__state[__MTGP11213_LENGTH] = *prng.__pos;
}


#undef M
#undef MASK
#undef SH1
#undef SH2

#endif