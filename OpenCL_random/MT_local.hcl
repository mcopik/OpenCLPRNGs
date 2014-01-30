#ifndef __MT_LOCAL_H
#define __MT_LOCAL_H


/**
 * @file MT_local.hcl
 * 
 * @brief Implements the functionality of Mersenne-Twister which operates on local memory
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
	__local uint * const __state; /**< \private */
	/** sync[0] can be used freely by the user */
	__local volatile uint * const sync;
	__private uint * const __pos; /**< \private */
} MT_PRNG;


/**
 * This macro creates and initializes an object of type MT_PRNG named \b prng. It has to be called from a kernel, but the object \b prng may also be used in functions.
 * @param prng the name of the object to be created
 * @param[in] state is a kernel argument of type {@link MT_state} pointing to the state of the PRNGs in global memory
 */
#define MT_init( prng, state ) \
	uint __mt_pos_##state; \
	__local uint __mt_state_##state[__MT_LENGTH]; \
	__local volatile uint __mt_sync_##state[3]; \
	if( __rnd_value_check( state, __MT_ID, 226 ) ) \
		return; \
	const MT_PRNG prng = { state, __mt_state_##state, __mt_sync_##state, &__mt_pos_##state }; \
	__rnd_load_state( prng.__state, prng.__mt, prng.__pos, __MT_LENGTH ); 
	
	
#include "random_cl/MersenneTwister.hcl"


/**
 * This function saves the state of an object of type MT_PRNG to global memory. It has to be called before a kernel, in which the PRNG is called, returns.
 * @param prng the MT_PRNG object to be saved
 */
inline void MT_save( MT_PRNG prng )
{
	__rnd_save_state( prng.__mt, prng.__state, *prng.__pos, __MT_LENGTH );
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
	__rnd_barrier( CLK_LOCAL_MEM_FENCE );
	uint pos = *prng.__pos;
	uint h = (STATE[pos] & HIGH_MASK) | (STATE[ pos+1 - (pos == __MT_LENGTH-1) * __MT_LENGTH ] & LOW_MASK);
	h = STATE[ pos+M - (pos >= __MT_LENGTH-M) * __MT_LENGTH ] ^ (h >> 1) ^ ((h & 1) * 0x9908b0df);
	if( sync )
		prng.sync[1] = 1;
	__rnd_barrier( CLK_LOCAL_MEM_FENCE );
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
