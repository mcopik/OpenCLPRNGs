#ifndef __MOTHER_LOCAL_H
#define __MOTHER_LOCAL_H

/**
 * @file Mother_local.hcl
 * 
 * @brief Mother-of-All generator as used by Agner Fog, which is a Multiply with Carry Generator invented by George Marsaglia. This implementation operates on local memory and the work-group size has to be known at OpenCL-compile-time.
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
	__local uint * const __state; /**< \private */
	/** sync[0] can be freely used by the user */
	__local volatile uint * const sync;
	__private const uint * const __pos; /**< \private */
} Mother_PRNG;



/**
 * This macro creates and initializes an object of type Mother_PRNG named \b prng. It has to be called from a kernel, but the object \b prng may also be used in functions.
 * @param prng the name of the Mother_PRNG object to be created
 * @param[in] state is a kernel argument of type Mother_state pointing to the state of the PRNGs in global memory
 */
#ifndef __RND_WORKGROUP_SIZE
#define Mother_init( prng, state ) \
	#error "The local version of Mother_PRNG works only when the work-group size is known at compile-time"
#else
#define Mother_init( prng, state ) \
	__private const uint __mother_pos_##state = __rnd_get_local_id(); \
 	__local volatile uint __mother_sync_##state[1]; \
	__local uint __mother_state_##state[ __MOTHER_LENGTH * __RND_WORKGROUP_SIZE ]; \
	if( __rnd_value_check( state, __MOTHER_ID, (uint)(-1) ) ) \
		return; \
	const Mother_PRNG prng = { state, __mother_state_##state, __mother_sync_##state, &__mother_pos_##state }; \
	{ \
		const uint group_id = __rnd_get_group_id(); \
		\
		const uint size = __RND_WORKGROUP_SIZE * __MOTHER_LENGTH; \
		event_t event = async_work_group_copy( __mother_state_##state, state + group_id * size + __OFFSET, size, 0 ); \
		wait_group_events( 1, &event ); \
		barrier( CLK_GLOBAL_MEM_FENCE ); \
	}

#endif


#include "random_cl/Mother.hcl"


/**
 * This function saves a Mother-of-All PRNG state of a work-group in global memory. It has to be called before a kernel, in which the PRNG is called, returns.
 * @param prng Mother_PRNG object to save
 */
inline void Mother_save( Mother_PRNG prng )
{
	uint group_id = __rnd_get_group_id();
	
	barrier( CLK_LOCAL_MEM_FENCE );
	const uint size = __MOTHER_LENGTH * __RND_WORKGROUP_SIZE;
	event_t event = async_work_group_copy( prng.__mother + group_id * size + __OFFSET, prng.__state, size, 0 );
	wait_group_events( 1, &event );
	barrier( CLK_GLOBAL_MEM_FENCE );
}


#define IDX(x) ( (x) * __RND_WORKGROUP_SIZE + pos )
#define STATE prng.__state

/**
 * This functions generates uniformly distributed 32bit random integers
 * @param prng Mother_PRNG object to use for random number generation
 * @return 32bit random integer
 */
inline uint Mother_random( Mother_PRNG prng )
{
	__private const uint pos = *prng.__pos;
	ulong sum = (ulong)STATE[IDX(3)]*2111111111 + (ulong)STATE[IDX(2)]*1492 + (ulong)STATE[IDX(1)]*1776 + (ulong)STATE[pos]*5115 + (ulong)STATE[IDX(4)];
/*	ulong sum = (ulong)STATE[IDX(3)]*2111111111 + (ulong)( mad( (double)STATE[IDX(2)], 1492, 
																  mad( (double)STATE[IDX(1)], 1776, 
																	   mad( (double)STATE[pos], 5115, (double)STATE[IDX(4)] ))));*/
	STATE[IDX(3)] = STATE[IDX(2)];
	STATE[IDX(2)] = STATE[IDX(1)];
	STATE[IDX(1)] = STATE[pos];
	STATE[IDX(4)] = sum>>32;
	STATE[pos] = sum;
	return sum;
}

#undef STATE
#undef IDX



#endif