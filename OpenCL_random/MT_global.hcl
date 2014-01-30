#ifndef __MT_GLOBAL_H
#ifndef DOXYGEN
#define __MT_GLOBAL_H
#endif


/**
 * @file MT_global.hcl
 * 
 * @brief Implements the functionality of Mersenne-Twister which operates on global memory
 * 
 * @author Philipp Otterbein
 */


/**
 * A {@link MT_state} object points to Mersenne Twister PRNG streams in global device memory and is used as kernel argument
 */
typedef __global uint* MT_state;

/**
 * MT_PRNG represents a by {@link MT_init} initialized Mersenne-Twister PRNG object on device side
 */
typedef struct
{
	MT_state const __mt; /**< \private */
	__global uint * const __state; /**< \private */
	/** sync[0] can be used freely by the user */
	__local volatile uint * const sync;
	__private uint * const __pos; /**< \private */
} MT_PRNG;


#include "random_cl/MersenneTwister.hcl"

/**
 * \internal
 * This function is used for initializiation of a MT_PRNG object
 */

inline __global uint *__mt_init( MT_state state, __private uint *ptr_pos )
{
	uint local_id = __rnd_get_local_id();
#ifndef __RND_WORKGROUP_SIZE
	if( local_id == 0 )
		state[0] = __rnd_get_workgroup_size();
#endif
	uint offset = __rnd_get_group_id() * (__MT_LENGTH + 1) + __OFFSET;
	uint pos = state[ offset + __MT_LENGTH ] + local_id;
	pos -= (pos >= __MT_LENGTH) * __MT_LENGTH;
	*ptr_pos = pos;
	return state + offset;
}


/**
 * This macro creates and initializes an object of type MT_PRNG named \b prng. It has to be called from a kernel, but the object \b prng may also be used in functions.
 * @param prng the name of the object to be created
 * @param[in] state is a kernel argument of type {@link MT_state} pointing to the state of the PRNGs in global memory
 */
#define MT_init( prng, state ) \
	uint __mt_pos_##state; \
	__local volatile uint __mt_sync_##state[3]; \
	if( __rnd_value_check( state, __MT_ID, 226 ) ) \
		return; \
	const MT_PRNG prng = { state, __mt_init( state, &__mt_pos_##state ), __mt_sync_##state, &__mt_pos_##state }


/**
 * This function saves the state of an object of type MT_PRNG to global memory. It has to be called before a kernel, in which the PRNG is called, returns.
 * @param prng the MT_PRNG object to be saved
 */
inline void MT_save( MT_PRNG prng )
{
	if( __rnd_get_local_id() == 0 )
		prng.__state[__MT_LENGTH] = *prng.__pos;
}


#define STATE prng.__state
/**
 * \internal
 * This internal function provides the functionality of the MT_PRNG. It returns uniformly distributed 32bit random integers.
 * @param prng PRNG object to use for random number generation
 * @param sync specifies whether \b prng .sync[1] shall be set
 * @return unsigned 32bit random integer
 */
inline uint __MT_random( MT_PRNG prng, bool sync )
{
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	uint pos = *prng.__pos;
	uint h = (STATE[pos] & HIGH_MASK) | (STATE[ pos+1 - (pos == __MT_LENGTH-1) * __MT_LENGTH ] & LOW_MASK);
	h = STATE[ pos+M - (pos >= __MT_LENGTH-M) * __MT_LENGTH ] ^ (h >> 1) ^ ((h & 1) * 0x9908b0df);
	if( sync )
	{
		mem_fence( CLK_LOCAL_MEM_FENCE );
		prng.sync[1] = 1;
		mem_fence( CLK_LOCAL_MEM_FENCE );
	}
	__rnd_barrier( CLK_GLOBAL_MEM_FENCE );
	STATE[pos] = h;
#ifndef __RND_WORKGROUP_SIZE
	pos += *prng.__mt;
#else
	pos += __RND_WORKGROUP_SIZE;
#endif
	*prng.__pos = pos - (pos >= __MT_LENGTH) * __MT_LENGTH;
	return h;
}
#undef STATE



#undef M
#undef HIGH_MASK
#undef LOW_MASK


#endif