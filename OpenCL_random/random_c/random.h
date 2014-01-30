#ifndef __CL_RANDOM_H
#define __CL_RANDOM_H

/**
 * @file random.h
 * 
 * @brief This header implements functions which allow the host-side initialization and management of OpenCL-pseudorandom number generators for a device.
 * 
 * @author Philipp Otterbein
 */


#define __RND_HOST_ALLOC 2
#define __RND_DEVICE_ALLOC 1

#if __STDC_VERSION__ >= 199901L
	#define C99
#else
	#define inline
#endif



/** 
 * \internal 
 * Mother-of-All PRNG by Agner Fog: www.agner.org/random
 * @param state pointer to the state of a generator
 */
static cl_uint __rnd_mother( cl_uint *state )
{
	cl_ulong sum = (cl_ulong)state[3]*2111111111 + (cl_ulong)state[2]*1492 + (cl_ulong)state[1]*1776 + (cl_ulong)state[0]*5115 + (cl_ulong)state[4];
	state[3] = state[2];
	state[2] = state[1];
	state[1] = state[0];
	state[4] = sum>>32;
	state[0] = sum;
	return state[0];
}

/** 
 * \internal 
 * Initialization function no. 1 for Mother-of-All generator
 * @param state pointer to the state of a Mother-of-All generator
 * @param seed seed for a linear congruential generator
 */
inline static void __rnd_mother_init1( cl_uint *state, cl_uint seed )
{
	cl_uint s = seed;
	int i;
	for( i = 0; i < 5; i++ )
	{
		s = s * 29943829 - 1;
		state[i] = s;
	}
	for( i = 0; i < 23; i++)
		__rnd_mother( state );
}

/** 
 * \internal 
 * Initialization function no. 2 for Mother-of-All generator
 * @param state pointer to the state of a Mother-of-All generator
 * @param seed seed for a linear congruential generator
 */
inline static void __rnd_mother_init2( cl_uint *state, cl_uint seed )
{
	cl_uint s = seed;
	int i;
	for( i = 0; i < 5; i++ )
	{
		s = (1812433253UL * (s ^ (s >> 30)) + i);
		state[i] = s;
	}
	for( i = 0; i < 19; i++)
		__rnd_mother( state );
}

/** \internal */
inline static void aes_init( cl_uint *array, const int length, const cl_uint seed )
{
	const int key_length = 4; 	/* key_length = 4: 128 bit, key_length = 6: 192 bit, key_length = 8: 256 bit */
	int i;
#ifdef C99
	cl_uint dest[length];
#else 
	cl_uint *dest = (cl_uint*) malloc( length * sizeof(cl_uint) );
#endif
	cl_uint mother_state[__MOTHER_LENGTH];
	unsigned char iv[16];
	aes_context context;
	cl_uint key[key_length];
	__rnd_mother_init2( mother_state, seed );
	for( i = 0; i < 4; i++ )
		*((cl_uint*)iv + i) = __rnd_mother( mother_state );
	for( i = 0; i < key_length; i++ )
		key[i] = __rnd_mother( mother_state );
	aes_setkey_enc( &context, (const unsigned char*)key, key_length*32 );
	aes_crypt_cbc( &context, AES_ENCRYPT, length*4, iv, (unsigned char*)array, (unsigned char*)dest );
	memcpy( array, dest, length*4 );
#ifndef C99
	free(dest);
#endif
}


/**
 * CL_PRNG can represent any pseudo random number generator object on host side
 */
typedef struct
{
	cl_uint *__host_state; /**< \private */
	cl_mem __device_state; /**< \private */
	cl_context __context; /**< \private */
	int __num_prngs; /**< \private */
	int __info; /**< \private */
	unsigned int __ID; /**< \private */
} CL_PRNG;



/**
 * This host-side function appends a string with OpenCL compile-time information about the PRNGs to a user specified string, which is later used as argument for clBuildProgram.
 * @param[in,out] options specifies a string to which the information becomes appended. May be NULL
 * @param[in] header_file_path specifies a header search path of the OpenCL compiler
 * @param[in] local_size This argument specifies how many work-items will be in a work-group. An argument value <= 0 is used when this information is not known at OpenCL compile-time
 * @param[in] is_atomic This argument can be set to CL_TRUE when the work-group size is chosen such that work-items in a workgroup are executed in a atomic way, e.g. when the work-group size equals the number of work-items in a wavefront or in a warp
 * @param[in] debug specifies whether the debug mode shall be enabled. This may have a huge performance impact.
 * @return When \b options is NULL the number of characters that this function would append to \b options is returned. Otherwise 0 is returned.
 */
int CL_create_compile_string( char *const options, const char *const header_file_path, int local_size, cl_bool is_atomic, cl_bool debug )
{
	char tmp[1024];
#ifdef C99
	if( local_size > 0 )
		snprintf( tmp, 1024, " -D __RND_WORKGROUP_SIZE=%d%s%s -I %s", local_size, is_atomic ? " -D __RND_ATOMIC" : "", debug ? " -D RND_DEBUG" : "", header_file_path );
	else
		snprintf( tmp, 1024, "%s%s -I %s", is_atomic ? " -D __RND_ATOMIC" : "", debug ? " -D RND_DEBUG" : "", header_file_path );
#else
	if( local_size > 0 )
		sprintf( tmp, " -D __RND_WORKGROUP_SIZE=%d%s%s -I %s", local_size, is_atomic ? " -D __RND_ATOMIC" : "", debug ? " -D RND_DEBUG" : "", header_file_path );
	else
		sprintf( tmp, "%s%s -I %s", is_atomic ? " -D __RND_ATOMIC" : "", debug ? " -D RND_DEBUG" : "", header_file_path );
#endif
	if( options == NULL )
		return strlen( tmp ) + 1;
	strcat( options, tmp );
	return 0;
}


/** \internal */
inline static void __rnd_init( CL_PRNG *prng, cl_context context, size_t num_prngs, const cl_uint seed, cl_int *errcode_ret, const int length, const int id )
{
	int i;
	const int array_length = num_prngs * (length + 1);
	cl_uint mother_state[__MOTHER_LENGTH];
	cl_uint *mem = (cl_uint*) calloc( array_length + __OFFSET + 3, sizeof(cl_uint) );
	__rnd_mother_init1( mother_state, seed );
	for( i = 0; i < array_length; i++ ) {
		//mem[i + __OFFSET] = __rnd_mother( mother_state );
		mem[i] = __rnd_mother(mother_state);
//		for(int j = 0;j < __OFFSET;++j)
//			__rnd_mother(mother_state);
	}
	for( i = 0; i < num_prngs; i++ )
	{
		aes_init( mem + i * (length + 1) + __OFFSET, (length + 3) & ~3, i + 1 );
		if( id < __PER_WORKITEM_IDS )
			mem[ (i + 1) * (length + 1) + __OFFSET - 1 ] = 0;
	}
	mem[0] = 0;
	mem[1] = id;
	mem[2] = num_prngs;
	prng->__device_state = clCreateBuffer( context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sizeof(cl_uint) * (array_length + __OFFSET), mem, errcode_ret );
	prng->__host_state = NULL;
	prng->__num_prngs = num_prngs;
	prng->__info = __RND_DEVICE_ALLOC;
	prng->__context = context;
	prng->__ID = id;
	free(mem);
}


/**
 * \internal
 * This host-side function creates a new CL_PRNG object by copying a serialized PRNG from host memory to device memory. After that the old CL_PRNG object may be released
 * @param[out] r pointer to the newly created CL_PRNG object
 * @param[in] prng pointer to the serialized PRNG to be copied to device memory
 * @param[in] context see clCreateBuffer
 * @param[out] errcode_ret see clCreateBuffer
 * @param[in] length length of the state of one PRNG stream
 */
static inline void __cl_prng_load_serialized( CL_PRNG *r, CL_PRNG *prng, cl_context context, cl_int *errcode_ret, const int length )
{
	const int size = prng->__num_prngs * (length + 1);
	r->__device_state = clCreateBuffer( context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sizeof(cl_uint) * (size + __OFFSET), prng->__host_state, errcode_ret );
	r->__host_state = NULL;
	r->__num_prngs = prng->__num_prngs;
	r->__info = __RND_DEVICE_ALLOC;
	r->__context = context;
	r->__ID = prng->__ID;
}


/**
 * \internal
 * This host-side function copies a serialized PRNG from host memory to device memory using the device buffer associated with the serialized PRNG. Therefore, the device buffer must not be released previously to the call of this function
 * @param prng pointer to the CL_PRNG object to be deserialized
 * @param[in] queue see clEnqueueWriteBuffer
 * @param[in] blocking_write see clEnqueueWriteBuffer
 * @param[in] num_events_in_wait_list see clEnqueueWriteBuffer
 * @param[in] event_wait_list see clEnqueueWriteBuffer
 * @param[out] event see clEnqueueWriteBuffer
 * @param[in] length length of the state of one PRNG stream
 * @return returns CL_INVALID_MEM_OBJECT if the device buffer was released previously and otherwise it returns the return value of clEnqueueWriteBuffer
 */
static inline cl_int __cl_prng_deserialize( CL_PRNG *prng, cl_command_queue queue, cl_bool blocking_write, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event, const int length )
{
	const int size = (prng->__num_prngs * (length + 1) + __OFFSET) * sizeof(cl_uint);
	cl_int ret = CL_INVALID_MEM_OBJECT;
	if( (prng->__info & __RND_DEVICE_ALLOC) && (prng->__info & __RND_HOST_ALLOC) )
		ret = clEnqueueWriteBuffer( queue, prng->__device_state, blocking_write, 0, size, prng->__host_state, num_events_in_wait_list, event_wait_list, event );
	return ret;
}


/**
 * \internal
 * This host-side functions copies the state of a PRNG in device memory to host memory. After that the device memory may be released.
 * @param[in,out] prng pointer to CL_PRNG object to be serialized
 * @param[in] queue see clEnqueueReadBuffer
 * @param[in] blocking_read see clEnqueueReadBuffer
 * @param[in] num_events_in_wait_list see clEnqueueReadBuffer
 * @param[in] event_wait_list see clEnqueueReadBuffer
 * @param[out] event see clEnqueueReadBuffer
 * @param[in] length length of the state of one PRNG stream
 * @return the return value of clEnqueueReadBuffer
 */
static inline cl_int __cl_prng_serialize( CL_PRNG *prng, cl_command_queue queue, cl_bool blocking_read, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event, const int length )
{
	const int size = (prng->__num_prngs * (length + 1) + __OFFSET) * sizeof(cl_uint);
	if( !prng->__host_state )
		prng->__host_state = (cl_uint*) malloc( size );
	prng->__info |= __RND_HOST_ALLOC;
	return clEnqueueReadBuffer( queue, prng->__device_state, blocking_read, 0, size, prng->__host_state, num_events_in_wait_list, event_wait_list, event );
}


/**
 * \internal
 * This host-side function sets the PRNG_state argument of a kernel
 * @param[in] prng pointer to the CL_PRNG object to use in the kernel
 * @param kernel see clSetKernelArg
 * @param[in] arg_index the index of the PRNG_state argument, see clSetKernelArg
 * @return returns the return value of clSetKernelArg
 */
cl_int CL_PRNG_set_kernel_arg( const CL_PRNG *const prng, cl_kernel kernel, cl_uint arg_index )
{
	return clSetKernelArg( kernel, arg_index, sizeof(cl_mem), &(prng->__device_state) );
}


/**
 * \internal
 * This host-side function releases the device buffer allocated by a CL_PRNG object. Useful when an object is serialized and lies in host memory.
 * @param prng pointer to the CL_PRNG object which has allocated the device buffer
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
inline cl_int CL_PRNG_device_mem_release( CL_PRNG *const prng )
{
	cl_int error_code = CL_SUCCESS;
	if( prng->__info & __RND_DEVICE_ALLOC )
		error_code = clReleaseMemObject( prng->__device_state );
	prng->__info &= ~__RND_DEVICE_ALLOC;
	return error_code;
}


/**
 * \internal
 * This host-side function releases all buffers allocated by a CL_PRNG object. This includes device buffers and host buffers.
 * @param prng pointer to the CL_PRNG object which shall be released
 * @return CL_SUCCESS if the functions executes successfully. Otherwise an appropriate errorcode is returned.
 */
inline cl_int CL_PRNG_release( CL_PRNG *prng )
{
	cl_int error_code = CL_SUCCESS;
	if( prng->__info & __RND_DEVICE_ALLOC )
		error_code = clReleaseMemObject( prng->__device_state );
	if( prng->__host_state )
	{
		free( prng->__host_state );
		prng->__host_state = NULL;
	}
	prng->__info = 0;
	return error_code;
}


/**
 * \internal
 * compiles and returns a kernel
 */
#define __cl_ziggurat_normal_create_kernel( PRNG, ADDR_QUAL, _type, TYPE, T ) \
/** This host-side functions compiles a kernel, which generates normally distributed random _type##s by applying the Ziggurat algorithm to the output of PRNG##_random##T working in ADDR_QUAL memory of the device. \n @param[in] context the context in which to create the program \n @param[in] num_devices number of devices in \b device_list. If \b device_list is NULL, the first \b num_devices of devices associated with \b context are used. \b num_devices = 0 means all devices associated with \b context are used. \n @param[in] device_list list of devices for which the kernel shall be created. If \device_list is NULL, the devices associated with \b context are used \n @param[in] options the compile options to use \n @param[in] pfn_notify the callback function used by clBuildProgram, which analyzes the build log \n @param[in] user_data second argument of \b pfn_notify. May be NULL. \n @param[out] errcode_ret return an appropriate error code. May be NULL. */ \
cl_kernel CL_##PRNG##_##ADDR_QUAL##_ziggurat_normal_##_type##T##_create_kernel( cl_context context, cl_uint num_devices, const cl_device_id *device_list, const char *options, void (*pfn_notify)(cl_program, void *user_data), void *user_data, cl_int *errcode_ret ) \
{ \
	char source_string[] = "#define DISABLE_DOUBLES\n" "#undef DISABLE_" #TYPE "S\n" "#define ZIGGURAT_NORMAL_" #TYPE "\n" "#include \"" #PRNG "_" #ADDR_QUAL ".hcl\"\n" "#ifndef __RND_WORKGROUP_SIZE\n" "__kernel __ziggurat_normal_" #_type "_kernel( " #PRNG ", " #T " );\n" "#else\n"  "__kernel __attribute__((reqd_work_group_size(__RND_WORKGROUP_SIZE, 1, 1))) __ziggurat_normal_" #_type "_kernel( " #PRNG ", " #T " );\n" "#endif"; \
	cl_int errcode; \
	if( errcode_ret == NULL ) \
		errcode_ret = &errcode; \
	volatile char *tmp_source_string = &source_string[0]; \
	cl_program program = clCreateProgramWithSource( context, 1, (const char**) &tmp_source_string, NULL, errcode_ret ); \
	if( *errcode_ret != CL_SUCCESS ) \
		return NULL; \
	cl_bool alloc; \
	cl_device_id *tmp = (cl_device_id *) device_list; \
	if( alloc = (device_list == NULL) ) \
	{ \
		size_t size; \
		*errcode_ret = clGetContextInfo( context, CL_CONTEXT_DEVICES, 0, NULL, &size ); \
		if( *errcode_ret != CL_SUCCESS ) \
			return NULL; \
		if( num_devices == 0 || num_devices > (size / sizeof(cl_device_id)) ) \
			num_devices = size / sizeof(cl_device_id); \
		tmp = (cl_device_id *)malloc( size ); \
		*errcode_ret = clGetContextInfo( context, CL_CONTEXT_DEVICES, size, tmp, NULL ); \
		if( *errcode_ret != CL_SUCCESS ) \
			return NULL; \
	} \
	*errcode_ret = clBuildProgram( program, num_devices, tmp, options, pfn_notify, user_data ); \
	if( *errcode_ret != CL_SUCCESS ) \
		return NULL; \
	cl_build_status status = CL_BUILD_IN_PROGRESS; \
	int i; \
	for( i = 0; i < num_devices; i++ ) \
	{ \
		while( status == CL_BUILD_IN_PROGRESS ) \
			clGetProgramBuildInfo( program, tmp[i], CL_PROGRAM_BUILD_STATUS, sizeof(cl_build_status), &status, NULL ); \
		if( status != CL_BUILD_SUCCESS ) \
			return NULL; \
	} \
	cl_kernel kernel = clCreateKernel( program, #PRNG "_ziggurat_normal_" #_type #T "_kernel", errcode_ret ); \
	clReleaseProgram( program ); \
	if( alloc ) \
		free( tmp ); \
	return kernel; \
}


/**
 * This object represents a job, which can be executed by {@link CL_PRNG_ziggurat_normal} and will create normally distributed random numbers by using the Ziggurat algorithm
 */
typedef struct
{
	cl_kernel __kernel; /**< \private */
	cl_mem __tmp_buffer; /**< \private */
	float __buffer_size; /**< \private */
	cl_uint __global_work_size; /**< \private */
	cl_uint __local_work_size; /**< \private */
	cl_uint rnds_per_workitem; /** controls how many normally distributed numbers each work-item should return */
} CL_ziggurat_normal_job;



CL_ziggurat_normal_job __cl_ziggurat_normal_create_job( cl_mem *dest, cl_mem tmp_buffer, cl_kernel kernel, const cl_uint global_work_size, const cl_uint local_work_size, const cl_uint rnds_per_workitem, float buffer_size, cl_int *errcode_ret, cl_uint type_size )
{
	CL_ziggurat_normal_job job;
	cl_int errcode;
	if( errcode_ret == NULL )
		errcode_ret = &errcode;
	cl_context context;
	*errcode_ret = clGetKernelInfo( kernel, CL_KERNEL_CONTEXT, sizeof(cl_context), &context, NULL );
	if( *errcode_ret != CL_SUCCESS )
		return job;
	if( dest != NULL )
		*dest = clCreateBuffer( context, CL_MEM_READ_WRITE, (size_t) type_size * global_work_size * rnds_per_workitem, NULL, errcode_ret );
	if( *errcode_ret != CL_SUCCESS )
		return job;
	cl_uint num_workgroups = global_work_size / local_work_size;
	if( buffer_size <= 0.f || buffer_size > 1.f )
		buffer_size = 1.f;
	if( !tmp_buffer )
		job.__tmp_buffer = clCreateBuffer( context, CL_MEM_READ_WRITE, (size_t) sizeof(cl_uint) * num_workgroups * (cl_uint)(2 * local_work_size * rnds_per_workitem * buffer_size), NULL, errcode_ret );
	else
		job.__tmp_buffer = tmp_buffer;
	if( *errcode_ret != CL_SUCCESS )
		return job;
	job.__buffer_size = buffer_size;
	job.__global_work_size = global_work_size;
	job.__local_work_size = local_work_size;
	job.__kernel = kernel;
	job.rnds_per_workitem = rnds_per_workitem;
	return job;
}


/** 
 * This host-side function defines a job, which can later be used by {@link CL_PRNG_ziggurat_normal} to create normally distributed random floats on a device using the Ziggurat algorithm
 * @param[out] dest if not NULL, a cl_mem object is allocated and returned, which will hold the normally distributed random numbers. \n size: sizeof(_type) * \b global_work_size * \b rnds_per_workitem bytes
 * @param[in] tmp_buffer if not NULL, this buffer is used as temporary buffer for the algorithm, otherwise a buffer is allocated.\n size: sizeof(cl_uint) * num_workgroups * (cl_uint)(2 * \b local_work_size * \b rnds_per_workitem * \b buffer_size) bytes
 * @param[in] kernel previously created kernel, which uses the Ziggurat algorithm for generating normally distributed random floats
 * @param[in] buffer_size relative size of \b tmp_buffer. values of 0.f and 1.f are absolutely safe. for large data sets, e.g. \b buffer_size = 0.1f may be safe
 * @param[out] errcode_ret return an appropriate error code
 * @return the CL_ziggurat_normal_job object 
 */
inline CL_ziggurat_normal_job CL_ziggurat_normal_float_create_job( cl_mem *dest, cl_mem tmp_buffer, cl_kernel kernel, const cl_uint global_work_size, const cl_uint local_work_size, const cl_uint rnds_per_workitem, float buffer_size, cl_int *errcode_ret ) 
{
	return __cl_ziggurat_normal_create_job( dest, tmp_buffer, kernel, global_work_size, local_work_size, rnds_per_workitem, buffer_size, errcode_ret, sizeof(float) );
}


/** 
 * This host-side function defines a job, which can later be used by {@link CL_PRNG_ziggurat_normal} to create normally distributed random doubles on a device using the Ziggurat algorithm
 * @param[out] dest if not NULL, a cl_mem object is allocated and returned, which will hold the normally distributed random numbers. \n size: sizeof(_type) * \b global_work_size * \b rnds_per_workitem bytes
 * @param[in] tmp_buffer if not NULL, this buffer is used as temporary buffer for the algorithm, otherwise a buffer is allocated.\n size: sizeof(cl_uint) * num_workgroups * (cl_uint)(2 * \b local_work_size * \b rnds_per_workitem * \b buffer_size) bytes
 * @param[in] kernel previously created kernel, which uses the Ziggurat algorithm for generating normally distributed random doubles
 * @param[in] buffer_size relative size of \b tmp_buffer. values of 0.f and 1.f are absolutely safe. for large data sets, e.g. \b buffer_size = 0.1f may be safe
 * @param[out] errcode_ret return an appropriate error code
 * @return the CL_ziggurat_normal_job object 
 */
inline CL_ziggurat_normal_job CL_ziggurat_normal_double_create_job( cl_mem *dest, cl_mem tmp_buffer, cl_kernel kernel, const cl_uint global_work_size, const cl_uint local_work_size, const cl_uint rnds_per_workitem, float buffer_size, cl_int *errcode_ret ) 
{
	return __cl_ziggurat_normal_create_job( dest, tmp_buffer, kernel, global_work_size, local_work_size, rnds_per_workitem, buffer_size, errcode_ret, sizeof(double) );
}


/**
 * This host-side functions executes a job on a device, which generates normally distributed random numbers using the Ziggurat sampling algorithm. There exists also a specialized function for each PRNG.
 * @param[out] dest specifies the cl_mem object, in which the generated numbers are returned
 * @param[in] queue see clEnqueueNDRangeKernel
 * @param[in] job {@link CL_ziggurat_normal_job} object, which describes the job
 * @param[in] prng pointer to the CL_PRNG object to use
 * @param[in] num_events_in_wait_list see clEnqueueNDRangeKernel
 * @param[in] event_wait_list see clEnqueueNDRangeKernel
 * @param[out] event see clEnqueueNDRangeKernel
 * @return CL_SUCCESS on success and an appropriate errorcode otherwise
 */
cl_int CL_PRNG_ziggurat_normal( cl_mem dest, cl_command_queue queue, CL_ziggurat_normal_job job, const CL_PRNG *const prng, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event )
{
	cl_int errcode_ret;
	cl_uint num_workgroups = job.__global_work_size / job.__local_work_size;
	if( prng->__ID < __PER_WORKITEM_IDS && num_workgroups > prng->__num_prngs || prng->__ID >= __PER_WORKITEM_IDS && job.__global_work_size > prng->__num_prngs )
		return CL_INVALID_WORK_GROUP_SIZE;
	clSetKernelArg( job.__kernel, 0, sizeof(cl_mem), &dest );
	clSetKernelArg( job.__kernel, 1, sizeof(cl_mem), &(job.__tmp_buffer) );
	CL_PRNG_set_kernel_arg( prng, job.__kernel, 2 );
	clSetKernelArg( job.__kernel, 3, sizeof(cl_uint), &(job.rnds_per_workitem) );
	clSetKernelArg( job.__kernel, 4, sizeof(cl_float), &(job.__buffer_size) );
	const size_t glob_wk_size[1] = {job.__global_work_size};
	const size_t loc_wk_size[1] = {job.__local_work_size};
	errcode_ret = clEnqueueNDRangeKernel( queue, job.__kernel, 1, NULL, glob_wk_size, loc_wk_size, num_events_in_wait_list, event_wait_list, event );
	return errcode_ret;
}


/**
 * This host-side function releases the temporary buffer associated with \b job. Whenever the temporary buffer was explicitly specified when creating \b job, it must not be released by clReleaseMemObject after this call
 * @param job the buffer related to \b job is released
 * @return CL_SUCCESS on success and an appropriate errorcode otherwise
 */
inline cl_int CL_ziggurat_normal_release_job( CL_ziggurat_normal_job job )
{
	return clReleaseMemObject( job.__tmp_buffer );
}


#endif
