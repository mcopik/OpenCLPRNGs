#ifndef __CL_MERSENNE_TWISTER_H
#define __CL_MERSENNE_TWISTER_H

/**
 * @file MersenneTwister.h
 * 
 * @brief This header implements functions which allow the host-side initialization and management of OpenCL Mersenne-Twister PRNGs for a device.
 * 
 * @author Philipp Otterbein
 */


#include "random.h"


/**
 * CL_MT represents a Mersenne Twister pseudo random number generator object on host side
 */
typedef struct
{
	/** \private */
	CL_PRNG mt;
} CL_MT;


/**
 * This host-side function initializes a Mersenne-Twister PRNG in device memory
 * @param[in] context see clCreateBuffer
 * @param[in] num_workgroups specifies the number of generators to be generated and is equal to the number of work-groups
 * @param[in] seed an initial seed for the PRNGs
 * @param[out] errcode_ret see clCreateBuffer
 * @return a CL_PRNG object
 */
CL_MT CL_MT_init( cl_context context, size_t num_workgroups, const cl_uint seed, cl_int *errcode_ret )
{
	CL_MT r;
	__rnd_init( (CL_PRNG*) &r, context, num_workgroups, seed, errcode_ret, __MT_LENGTH, __MT_ID );
	return r;
}


/**
 * This host-side function creates a new CL_MT object by copying a serialized Mersenne-Twister PRNG from host memory to device memory. After that the old CL_MT object may be released
 * @param[in] mt_state the serialized Mersenne-Twister PRNG to be copied to device memory
 * @param[in] context see clCreateBuffer
 * @param[out] errcode_ret see clCreateBuffer
 * @return the new CL_MT object representing the Mersenne-Twister PRNG in device memory
 */
CL_MT CL_MT_load_serialized( CL_MT mt_state, cl_context context, cl_int *errcode_ret )
{
	CL_MT r;
	__cl_prng_load_serialized( (CL_PRNG*) &r, (CL_PRNG*) &mt_state, context, errcode_ret, __MT_LENGTH );
	return r;
}


/**
 * This host-side function copies a serialized Mersenne-Twister PRNG from host memory to device memory using the device buffer associated with the serialized Mersenne-Twister PRNG. Therefore, the device buffer must not be released previously to the call of this function
 * @param mt the CL_MT object to be deserialized
 * @param[in] queue see clEnqueueWriteBuffer
 * @param[in] blocking_write see clEnqueueWriteBuffer
 * @param[in] num_events_in_wait_list see clEnqueueWriteBuffer
 * @param[in] event_wait_list see clEnqueueWriteBuffer
 * @param[out] event see clEnqueueWriteBuffer
 * @return returns CL_INVALID_MEM_OBJECT if the device buffer was released previously and otherwise it returns the return value of clEnqueueWriteBuffer
 */
cl_int CL_MT_deserialize( CL_MT mt, cl_command_queue queue, cl_bool blocking_write, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return __cl_prng_deserialize( (CL_PRNG*) &mt, queue, blocking_write, num_events_in_wait_list, event_wait_list, event, __MT_LENGTH );
}


/**
 * This host-side functions copies the state of a Mersenne-Twister PRNG in device memory to host memory. After that the device memory may be released.
 * @param[in,out] mt pointer to CL_MT object to be serialized
 * @param[in] queue see clEnqueueReadBuffer
 * @param[in] blocking_read see clEnqueueReadBuffer
 * @param[in] num_events_in_wait_list see clEnqueueReadBuffer
 * @param[in] event_wait_list see clEnqueueReadBuffer
 * @param[out] event see clEnqueueReadBuffer
 * @return the return value of clEnqueueReadBuffer
 */
cl_int CL_MT_serialize( CL_MT *mt, cl_command_queue queue, cl_bool blocking_read, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return __cl_prng_serialize( (CL_PRNG*) mt, queue, blocking_read, num_events_in_wait_list, event_wait_list, event, __MT_LENGTH );
}


/**
 * This host-side function sets the {@link MT_state} argument of a kernel
 * @param[in] mt the CL_MT object to use in the kernel
 * @param kernel see clSetKernelArg
 * @param[in] arg_index the index of the {@link MT_state} argument, see clSetKernelArg
 * @return returns the return value of clSetKernelArg
 */
static inline cl_int CL_MT_set_kernel_arg( const CL_MT mt, cl_kernel kernel, cl_uint arg_index )
{
	return CL_PRNG_set_kernel_arg( (const CL_PRNG *const) &mt, kernel, arg_index );
}


/**
 * This host-side function releases the device buffer allocated by a CL_MT object. Useful when an object is serialized and lies in host memory.
 * @param mt pointer to the CL_MT object which has allocated the device buffer
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
inline cl_int CL_MT_device_mem_release( CL_MT *mt )
{
	return CL_PRNG_device_mem_release( (CL_PRNG *const) mt );
}


/**
 * This host-side function releases all buffers allocated by a CL_MT object. This includes device buffers and host buffers.
 * @param mt pointer to the CL_MT object which shall be released
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
static inline cl_int CL_MT_release( CL_MT *mt )
{
	return CL_PRNG_release( (CL_PRNG *) mt );
}

__cl_ziggurat_normal_create_kernel( MT, local, float, FLOAT, );
__cl_ziggurat_normal_create_kernel( MT, local, float, FLOAT, T );
__cl_ziggurat_normal_create_kernel( MT, global, float, FLOAT, );
__cl_ziggurat_normal_create_kernel( MT, global, float, FLOAT, T );
__cl_ziggurat_normal_create_kernel( MT, local, double, DOUBLE, );
__cl_ziggurat_normal_create_kernel( MT, local, double, DOUBLE, T );
__cl_ziggurat_normal_create_kernel( MT, global, double, DOUBLE, );
__cl_ziggurat_normal_create_kernel( MT, global, double, DOUBLE, T );


/**
 * This host-side functions executes a job on a device, which generates normally distributed random numbers using the Ziggurat sampling algorithm.
 * @param[out] dest specifies the cl_mem object, in which the generated numbers are returned
 * @param[in] queue see clEnqueueNDRangeKernel
 * @param[in] job {@link CL_ziggurat_normal_job} object, which describes the job
 * @param[in] prng the CL_MT object to use
 * @param[in] num_events_in_wait_list see clEnqueueNDRangeKernel
 * @param[in] event_wait_list see clEnqueueNDRangeKernel
 * @param[out] event see clEnqueueNDRangeKernel
 * @return CL_SUCCESS on success and an appropriate errorcode otherwise
 */
inline cl_int CL_MT_ziggurat_normal( cl_mem dest, cl_command_queue queue, CL_ziggurat_normal_job job, CL_MT prng, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	return CL_PRNG_ziggurat_normal( dest, queue, job, (CL_PRNG *) &prng, num_events_in_wait_list, event_wait_list, event );
}


#endif
