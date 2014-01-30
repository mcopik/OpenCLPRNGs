#ifndef __CL_MOTHER_H
#define __CL_MOTHER_H

/**
 * @file Mother.h
 * 
 * @brief This header implements functions which allow the host-side initialization and management of OpenCL Mother-of-All PRNGs for a device.
 * 
 * @author Philipp Otterbein
 */


#include "random.h"


/**
 * CL_Mother represents a Mother-of-All pseudo random number generator object on host side
 */
typedef struct
{
	/** \private */
	CL_PRNG mother;
} CL_Mother;


/**
 * This host-side function initializes a Mother_PRNG in device memory
 * @param[in] context see clCreateBuffer
 * @param[in] num_workitems specifies the number of generators to be generated and is equal to the number of work-items
 * @param[in] seed an initial seed for the PRNGs
 * @param[out] errcode_ret see clCreateBuffer
 * @return a CL_Mother object
 */
CL_Mother CL_Mother_init( cl_context context, size_t num_workitems, const cl_uint seed, cl_int *errcode_ret )
{
	CL_Mother r;
	__rnd_init( (CL_PRNG*) &r, context, num_workitems, seed, errcode_ret, __MOTHER_LENGTH-1, __MOTHER_ID );
	return r;
}


/**
 * This host-side function creates a new CL_Mother object by copying a serialized Mother-of-All PRNG from host memory to device memory. After that the old CL_Mother object may be released
 * @param[in] mother_state the serialized Mother-of-All PRNG to be copied to device memory
 * @param[in] context see clCreateBuffer
 * @param[out] errcode_ret see clCreateBuffer
 * @return the new CL_Mother object representing the Mother-of-All PRNG in device memory
 */
CL_Mother CL_Mother_load_serialized( CL_Mother mother_state, cl_context context, cl_int *errcode_ret )
{
	CL_Mother r;
	__cl_prng_load_serialized( (CL_PRNG*) &r, (CL_PRNG*) &mother_state, context, errcode_ret, __MOTHER_LENGTH-1 );
	return r;
}


/**
 * This host-side function copies a serialized Mother-of-All PRNG from host memory to device memory using the device buffer associated with the serialized Mother-of-All PRNG. Therefore, the device buffer must not be released previously to the call of this function
 * @param mother the CL_Mother object to be deserialized
 * @param[in] queue see clEnqueueWriteBuffer
 * @param[in] blocking_write see clEnqueueWriteBuffer
 * @param[in] num_events_in_wait_list see clEnqueueWriteBuffer
 * @param[in] event_wait_list see clEnqueueWriteBuffer
 * @param[out] event see clEnqueueWriteBuffer
 * @return returns CL_INVALID_MEM_OBJECT if the device buffer was released previously and otherwise it returns the return value of clEnqueueWriteBuffer
 */
cl_int CL_Mother_deserialize( CL_Mother mother, cl_command_queue queue, cl_bool blocking_write, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return __cl_prng_deserialize( (CL_PRNG*) &mother, queue, blocking_write, num_events_in_wait_list, event_wait_list, event, __MOTHER_LENGTH-1 );
}


/**
 * This host-side functions copies the state of a Mother-of-All PRNG in device memory to host memory. After that the device memory may be released.
 * @param[in,out] mother pointer to CL_Mother object to be serialized
 * @param[in] queue see clEnqueueReadBuffer
 * @param[in] blocking_read see clEnqueueReadBuffer
 * @param[in] num_events_in_wait_list see clEnqueueReadBuffer
 * @param[in] event_wait_list see clEnqueueReadBuffer
 * @param[out] event see clEnqueueReadBuffer
 * @return the return value of clEnqueueReadBuffer
 */
cl_int CL_Mother_serialize( CL_Mother *mother, cl_command_queue queue, cl_bool blocking_read, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return __cl_prng_serialize( (CL_PRNG*) mother, queue, blocking_read, num_events_in_wait_list, event_wait_list, event, __MOTHER_LENGTH-1 );
}


/**
 * This host-side function sets the {@link Mother_state} argument of a kernel
 * @param[in] mother the CL_Mother object to use in the kernel
 * @param kernel see clSetKernelArg
 * @param[in] arg_index the index of the {@link Mother_state} argument, see clSetKernelArg
 * @return returns the return value of clSetKernelArg
 */
inline cl_int CL_Mother_set_kernel_arg( const CL_Mother mother, cl_kernel kernel, cl_uint arg_index )
{
	return CL_PRNG_set_kernel_arg( (const CL_PRNG *const) &mother, kernel, arg_index );
}


/**
 * This host-side function releases the device buffer allocated by a CL_Mother object. Useful when an object is serialized and lies in host memory.
 * @param mother pointer to the CL_Mother object which has allocated the device buffer
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
inline cl_int CL_Mother_device_mem_release( CL_Mother *mother )
{
	return CL_PRNG_device_mem_release( (CL_PRNG *const) mother );
}


/**
 * This host-side function releases all buffers allocated by a CL_Mother object. This includes device buffers and host buffers.
 * @param mother pointer to the CL_Mother object which shall be released
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
inline cl_int CL_Mother_release( CL_Mother *mother )
{
	return CL_PRNG_release( (CL_PRNG*) mother );
}

__cl_ziggurat_normal_create_kernel( Mother, private, float, FLOAT, );
__cl_ziggurat_normal_create_kernel( Mother, local, float, FLOAT, );
__cl_ziggurat_normal_create_kernel( Mother, global, float, FLOAT, );
__cl_ziggurat_normal_create_kernel( Mother, private, double, DOUBLE, );
__cl_ziggurat_normal_create_kernel( Mother, local, double, DOUBLE, );
__cl_ziggurat_normal_create_kernel( Mother, global, double, DOUBLE, );


/**
 * This host-side functions executes a job on a device, which generates normally distributed random numbers using the Ziggurat sampling algorithm.
 * @param[out] dest specifies the cl_mem object, in which the generated numbers are returned
 * @param[in] queue see clEnqueueNDRangeKernel
 * @param[in] job {@link CL_ziggurat_normal_job} object, which describes the job
 * @param[in] prng the CL_Mother object to use
 * @param[in] num_events_in_wait_list see clEnqueueNDRangeKernel
 * @param[in] event_wait_list see clEnqueueNDRangeKernel
 * @param[out] event see clEnqueueNDRangeKernel
 * @return CL_SUCCESS on success and an appropriate errorcode otherwise
 */
inline cl_int CL_Mother_ziggurat_normal( cl_mem dest, cl_command_queue queue, CL_ziggurat_normal_job job, CL_Mother prng, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return CL_PRNG_ziggurat_normal( dest, queue, job, (CL_PRNG *) &prng, num_events_in_wait_list, event_wait_list, event );
}


#endif