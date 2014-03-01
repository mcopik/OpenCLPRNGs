#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <CL/cl.h>

//OpenCL_random
#include "OpenCL_random/random_c.h"
#include "OpenCL_random/random_c/MersenneTwister.h"

#define NUMBER_OF_ITERATIONS 10
#define LOCAL_WORK_SIZE 64

#define MACRO_CONC(x,y) x## #y
#define MACRO_CONC2(x,y) MACRO_CONC(x,y)
//__LINE__ works with GNU GCC.
#define CL_CHECK_ERROR(status,expr) \
	status = expr; \
	if(status != CL_SUCCESS) { \
		printf("Error %d in " #expr " at line: %d\n",status,__LINE__); \
		return 1; \
	}

#define CL_CHECK_STATUS(status,expr) \
	if(status != CL_SUCCESS) { \
		printf("Status error %d in " #expr " at line: %d\n",status,__LINE__); \
		return 1; \
	}

int create_program(cl_program * program, const char * program_name,cl_context * context) {

	FILE * file = NULL;
	if(!strcmp(program_name,"mwc64x")) {
		file = fopen("mwc64x/sumKernel.cl","r");
	}
	else if(!strcmp(program_name,"random123")) {
		file = fopen("Random123/sumKernel.cl","r");
	}
	else if(!strcmp(program_name,"opencl_random")) {
		file = fopen("OpenCL_random/sumKernel.cl","r");
	}
	else if(!strcmp(program_name,"park_miller")) {
		file = fopen("Park_Miller/sumKernel.cl","r");
	}
	else {
		return 1;
	}
	assert(file != NULL);
	//I know, not 'pure' and portable
	fseek(file,0,SEEK_END);
	const unsigned long sourceSize = ftell(file);
	rewind(file);
	assert(sourceSize > 0);
	char * source = (char*)malloc(sizeof(char)*sourceSize);
	size_t result = fread(source,1,sourceSize,file);
	assert(result == sourceSize);
	fclose(file);
	*program = clCreateProgramWithSource(*context, 1, (const char**)&source, &sourceSize, NULL);
	free(source);
	return 0;
}

typedef struct _Random123Seed {
	cl_mem inputBuffer;
	long seed[3];
} Random123Seed;

typedef union {
	//mwc64x
	long seed;
	//OpenCL_random
	CL_MT prng;
	//Random123
	Random123Seed random123;
} argType;

int setArgs(argType * arg,cl_kernel kernel, const char * program_name,cl_context context,size_t workgroups_number) {
	srand(time(0));
	if(!strcmp(program_name,"mwc64x")) {
		arg->seed = time(0);
        	clSetKernelArg(kernel, 0, sizeof(cl_ulong), (void *)&arg->seed);
	}
	else if(!strcmp(program_name,"random123")) {
		arg->random123.seed[0] = rand();
		arg->random123.seed[1] = rand();
		arg->random123.seed[2] = rand();
		arg->random123.inputBuffer = clCreateBuffer(context,CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,sizeof(cl_ulong) * 2,arg->random123.seed,NULL);
        	clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&arg->random123.inputBuffer);
	}
	else if(!strcmp(program_name,"opencl_random")) {
		cl_int error_code;
       		arg->prng = CL_MT_init( context, workgroups_number, rand(), &error_code );
		CL_CHECK_STATUS(error_code,"Init OpenCL Random");
		CL_MT_set_kernel_arg( arg->prng, kernel, 0 );
	}
	else if(!strcmp(program_name,"park_miller")) {
		//TODO: implement this
	}
	else {
		return 1;
	}
	return 0;
}

void cleanUpArg(argType *arg, const char * program_name) {
	
	if(!strcmp(program_name,"random123")) {
		clReleaseMemObject(arg->random123.inputBuffer);
	}
	else if(!strcmp(program_name,"opencl_random")) {
		CL_MT_release(&arg->prng);
	}
	
}

int roundUp(int first,int second) {
	
	if(first % second == 0) {
		return first;
	}
	else {
		return first + (second - first % second);
	}
}

int main(int argc,char ** argv) {

	if(argc != 4) {
		printf("SYNTAX: number_of_samples number_of_sums_in_sample kernel_name\n");
		return 1;
	}
	int globalWorkSize = atoi(argv[1]);
	int count = atoi(argv[2]);
	const char * kernel_name = argv[3];

	//query platforms
	cl_uint numPlatforms;
	cl_int status;
	CL_CHECK_ERROR(status,clGetPlatformIDs(0, NULL, &numPlatforms));
	assert(numPlatforms > 0);	
	cl_platform_id * platforms = (cl_platform_id* ) malloc(numPlatforms* sizeof(cl_platform_id));
        CL_CHECK_ERROR(status,clGetPlatformIDs(numPlatforms,platforms,NULL));
	cl_platform_id platform = platforms[0];
        free(platforms);

	//query devices on platforms
	cl_uint numDevices;
	CL_CHECK_ERROR(status,clGetDeviceIDs(platform,CL_DEVICE_TYPE_ALL,0,NULL,&numDevices));
	assert(numDevices > 0);
	cl_device_id * devices = (cl_device_id*)malloc(numDevices*sizeof(cl_device_id));
	CL_CHECK_ERROR(status,clGetDeviceIDs(platform,CL_DEVICE_TYPE_ALL,numDevices,devices,NULL));

	cl_context context = clCreateContext(NULL,numDevices,devices,NULL,NULL,NULL);
	cl_command_queue commandQueue = clCreateCommandQueue(context, devices[0], CL_QUEUE_PROFILING_ENABLE, &status);
	CL_CHECK_STATUS(status,"Create command queue");
	//load proper kernel
	cl_program program;
	if(create_program(&program,kernel_name,&context)) {
		printf("Error during loading kernel and creating program!\n");
		return 1;
	}
	//build kernel
	status = clBuildProgram(program,1, devices, "-g -I mwc64x/cl -I OpenCL_random -I Random123/include", NULL, NULL);
	//check for kernel errors
	if (status != CL_SUCCESS)
        {
		size_t log_size;
		clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
		char *log = (char *) malloc(log_size);
		clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, log_size, log, NULL);
		printf("%s\n", log);
		free(log);
		return 1;
        }
	//kernel
	cl_kernel kernel = clCreateKernel(program, "main", &status);
	CL_CHECK_STATUS(status,"Create kernel");
	unsigned int sampleOffset = 0;
	//work size
	size_t gwSize[1];
        size_t lwSize[1];
	lwSize[0] = LOCAL_WORK_SIZE;
	size_t numberOfSamplesPerIteration = globalWorkSize/NUMBER_OF_ITERATIONS;
	gwSize[0] = roundUp(numberOfSamplesPerIteration,LOCAL_WORK_SIZE);

	//memory objects
	cl_mem outputBuffer = NULL;
	outputBuffer = clCreateBuffer(context,CL_MEM_WRITE_ONLY,sizeof(cl_float) * globalWorkSize,NULL,&status);
	CL_CHECK_STATUS(status,"Create output buffer");

	//kernel args which will not change
	argType prngArg;
	prngArg.seed = 0;
	assert(setArgs(&prngArg,kernel,kernel_name,context,gwSize[0]/lwSize[0]) == 0);
	clSetKernelArg(kernel, 1, sizeof(cl_uint), (void *)&count);
        clSetKernelArg(kernel, 3, sizeof(cl_mem), (void *)&outputBuffer);

	//execute
	size_t executed = 0;
	cl_event * events = (cl_event*) malloc(sizeof(cl_event)*globalWorkSize/gwSize[0]);
	int current = 0;
	while(executed < globalWorkSize) {
		//if it is possible to process smaller number of samples?
		if((globalWorkSize-executed) <  numberOfSamplesPerIteration) {
			gwSize[0] = roundUp(globalWorkSize-executed,LOCAL_WORK_SIZE);
		}

		clSetKernelArg(kernel, 2, sizeof(cl_uint), (void *)&sampleOffset);
		clEnqueueNDRangeKernel(commandQueue, kernel, 1, NULL, gwSize, lwSize, 0, NULL, &events[current++]);
                if (status != CL_SUCCESS)
                {
                        printf("Kernel enqueue failed! GW Size %zu, LW Size %zu, Error code %d\n",gwSize[0],lwSize[0],status);
			return 1;
                }
		sampleOffset += gwSize[0];
		executed += gwSize[0];
	}
	//compute execution time
	clock_t time = 0;
	cl_ulong profiling_start = 0,profiling_end = 0;
	clWaitForEvents(current,events);
	for(int i = 0;i < current;++i) {
		clGetEventProfilingInfo(events[i],CL_PROFILING_COMMAND_START,sizeof(cl_ulong),&profiling_start,NULL);
		clGetEventProfilingInfo(events[i],CL_PROFILING_COMMAND_END,sizeof(cl_ulong),&profiling_end,NULL);
		time += (profiling_end - profiling_start);
	}
	//read results
	cl_float * output = NULL;
	output = (cl_float*) malloc(sizeof(cl_float)*globalWorkSize);
	memset(output,0,sizeof(cl_float)*globalWorkSize);
	cl_event readEvt1;
	status = clEnqueueReadBuffer(commandQueue, outputBuffer, CL_TRUE,0,
                                 globalWorkSize * sizeof(cl_float),output,
                                 0,NULL,&readEvt1);
	clWaitForEvents(1,&readEvt1);
	CL_CHECK_STATUS(status,"Read buffer");

	//process results
	float avg = 0.0f;
	float min = output[0];
	float max = output[0];
	//average result, max, min
	for(int i = 0;i < globalWorkSize;++i) {
		avg += output[i];
		if(output[i] < min) {
			min = output[i];
		}
		if(output[i] > max) {
			max = output[i];
		}
	}
	avg /= globalWorkSize;
	float stdDev = 0.0f;
	//standard deviation
	for(int i = 0;i < globalWorkSize;++i) {
		stdDev += pow(output[i] - avg,2);
	}
	stdDev /= globalWorkSize;
	printf("Processing %d samples in %d iterations.\n Time %f seconds.\n Average value: %f.\n",globalWorkSize,NUMBER_OF_ITERATIONS,((float)time)/1000000.0,avg);
	printf("Standard deviation %f.\n Min %f.\n Max %f.\n",stdDev,min,max);
	//clean up!
	free(output);
	free(events);
	CL_CHECK_ERROR(status,clReleaseKernel(kernel));
	cleanUpArg(&prngArg,kernel_name);
	CL_CHECK_ERROR(status,clReleaseMemObject(outputBuffer));
 	CL_CHECK_ERROR(status,clReleaseProgram(program));
	CL_CHECK_ERROR(status,clReleaseCommandQueue(commandQueue));
	CL_CHECK_ERROR(status,clReleaseContext(context));
	if(devices != NULL) {
		free(devices);
	}
	return 0;
}
