#ifndef __MOTHER_LOCAL_H
#define __MOTHER_LOCAL_H

/**
 * @file Mother_private.hcl
 * 
 * @brief Mother-of-All generator as used by Agner Fog, which is a Multiply with Carry Generator invented by George Marsaglia. This implementation operates on private memory.
 * 
 * @author Philipp Otterbein
 */


/**
 * A {@link Mother_state} object points to Mother-of-All PRNG streams in global device memory and is used as kernel argument
 */
typedef __global uint* Mother_state;

/**
 * Mother_PRNG represents a by {@link Mother_init} initialized Mother-of-All PRNG object on device side
 */
typedef struct
{
	Mother_state const __mother; /**< \private */
	__private uint * const __state; /**< \private */
	/** sync[0] can be freely used by the user */
	__local volatile uint * const sync;
} Mother_PRNG;



/**
 * This macro creates and initializes an object of type Mother_PRNG named \b prng. It has to be called from a kernel, but the object \b prng may also be used in functions.
 * @param prng the name of the Mother_PRNG object to be created
 * @param[in] state is a kernel argument of type Mother_state pointing to the state of the PRNGs in global memory
 */
#define Mother_init( prng, state ) \
	uint __mother_state_##state[__MOTHER_LENGTH]; \
	__local volatile uint __mother_sync_##state[1]; \
	if( __rnd_value_check( state, __MOTHER_ID, (uint)(-1) ) ) \
		return; \
	const Mother_PRNG prng = { state, __mother_state_##state, __mother_sync_##state }; \
	{ \
		const uint group_id = __rnd_get_group_id(); \
		const uint local_id = __rnd_get_local_id(); \
		\
		const uint wk_size = __rnd_get_workgroup_size(); \
		__global const uint *const ptr = state + group_id * wk_size * __MOTHER_LENGTH + __OFFSET; \
		__mother_state_##state[0] = ptr[local_id]; \
		__mother_state_##state[1] = ptr[local_id + wk_size]; \
		__mother_state_##state[2] = ptr[local_id + 2 * wk_size]; \
		__mother_state_##state[3] = ptr[local_id + 3 * wk_size]; \
		__mother_state_##state[4] = ptr[local_id + 4 * wk_size]; \
	} \
	barrier( CLK_GLOBAL_MEM_FENCE );


#include "random_cl/Mother.hcl"


/**
 * This function saves a Mother-of-All PRNG state of a work-group in global memory. It has to be called before a kernel, in which the PRNG is called, returns.
 * @param prng Mother_PRNG object to save
 */
inline void Mother_save( Mother_PRNG prng )
{
	const uint group_id = __rnd_get_group_id();
	const uint local_id = __rnd_get_local_id();
	const uint wk_size = __rnd_get_workgroup_size();
	__global uint *const ptr = prng.__mother + group_id * wk_size * __MOTHER_LENGTH + __OFFSET; 
	ptr[local_id] = prng.__state[0];
	ptr[local_id + wk_size] = prng.__state[1];
	ptr[local_id + 2 * wk_size] = prng.__state[2];
	ptr[local_id + 3 * wk_size] = prng.__state[3];
	ptr[local_id + 4 * wk_size] = prng.__state[4];
}

#define STATE prng.__state

/**
 * This functions generates uniformly distributed 32bit random integers
 * @param prng Mother_PRNG object to use for random number generation
 * @return 32bit random integer
 */
inline uint Mother_random( Mother_PRNG prng )
{
	ulong sum = (ulong)STATE[3]*2111111111 + (ulong)STATE[2]*1492 + (ulong)STATE[1]*1776 + (ulong)STATE[0]*5115 + (ulong)STATE[4];
/*	ulong sum = (ulong)STATE[3]*2111111111 + (ulong)( mad( (double)STATE[2], 1492, 
											  mad( (double)STATE[1], 1776, 
												   mad( (double)STATE[0], 5115, (double)STATE[4] ))));*/
	STATE[3] = STATE[2];
	STATE[2] = STATE[1];
	STATE[1] = STATE[0];
	STATE[4] = sum>>32;
	STATE[0] = sum;
	return sum;
}

#undef STATE


#endif