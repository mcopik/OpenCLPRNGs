#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <CL/cl.h>

#define NUMBER_OF_ITERATIONS 10
#define LOCAL_WORK_SIZE 128


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

int setArgs(cl_kernel kernel, const char * program_name) {
	if(!strcmp(program_name,"mwc64x")) {
		long seed = time(0);
        	clSetKernelArg(kernel, 0, sizeof(cl_ulong), (void *)&seed);
	}
	else if(!strcmp(program_name,"random123")) {
	}
	else if(!strcmp(program_name,"opencl_random")) {
	}
	else if(!strcmp(program_name,"mwc64x")) {
	}
	else {
		return 1;
	}
	return 0;
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

	cl_int status;
	
	//query platforms
	cl_uint numPlatforms;
	status = clGetPlatformIDs(0, NULL, &numPlatforms);
	assert(status == CL_SUCCESS && numPlatforms > 0);	
	cl_platform_id * platforms = (cl_platform_id* )malloc(numPlatforms* sizeof(cl_platform_id));
        status = clGetPlatformIDs(numPlatforms,platforms,NULL);
	assert(status == CL_SUCCESS);
	cl_platform_id platform = platforms[0];
        free(platforms);
	
	//query devices on platforms
	cl_uint numDevices;
	status = clGetDeviceIDs(platform,CL_DEVICE_TYPE_ALL,0,NULL,&numDevices);
	assert(status == CL_SUCCESS && numDevices > 0);
	cl_device_id * devices = (cl_device_id*)malloc(numDevices*sizeof(cl_device_id));
	status = clGetDeviceIDs(platform,CL_DEVICE_TYPE_ALL,numDevices,devices,NULL);
	assert(status == CL_SUCCESS);

	cl_context context = clCreateContext(NULL,numDevices,devices,NULL,NULL,NULL);
	cl_command_queue commandQueue = clCreateCommandQueue(context, devices[0], 0, &status);
	//load proper kernel
	cl_program program;
	if(create_program(&program,kernel_name,&context)) {
		printf("Error during creating program\n");
		return 1;
	}
	//build kernel
	status = clBuildProgram(program,1, devices, "-Imwc64x/cl", NULL, NULL);
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
	assert(status == CL_SUCCESS);
	int sampleOffset = 0;
	//work size
	size_t gwSize[1];
        size_t lwSize[1];
	lwSize[0] = LOCAL_WORK_SIZE;
	size_t numberOfSamplesPerIteration = globalWorkSize/NUMBER_OF_ITERATIONS;
	gwSize[0] = roundUp(numberOfSamplesPerIteration,LOCAL_WORK_SIZE);
	//memory objects
	cl_mem outputBuffer = clCreateBuffer(context,CL_MEM_WRITE_ONLY,sizeof(cl_float) * globalWorkSize,NULL,&status);
	//kernel args which will not change
	assert(setArgs(kernel,kernel_name) == 0);
        clSetKernelArg(kernel, 1, sizeof(cl_uint), (void *)&count);
        clSetKernelArg(kernel, 3, sizeof(cl_mem), (void *)&outputBuffer);
	assert(status == CL_SUCCESS);
	//execute
	clock_t first = clock() / (CLOCKS_PER_SEC/1000);
	size_t executed = 0;
	while(executed < globalWorkSize) {
		//if it is possible to process smaller number of samples?
		if((globalWorkSize-executed+1) <  numberOfSamplesPerIteration) {
			gwSize[0] = roundUp(globalWorkSize-executed+1,LOCAL_WORK_SIZE);
		}
		clSetKernelArg(kernel, 2, sizeof(cl_uint), (void *)&sampleOffset);
		status = clEnqueueNDRangeKernel(commandQueue, kernel, 1, NULL, gwSize, lwSize, 0, NULL, NULL);
                if (status != CL_SUCCESS)
                {
                        printf("Kernel enqueue failed! GW Size %zu, LW Size %zu, Error code %d\n",gwSize[0],lwSize[0],status);
			return 1;
                }
		sampleOffset += gwSize[0];
		executed += gwSize[0];
	}
	status = clFinish(commandQueue);
        clock_t second = clock() / (CLOCKS_PER_SEC/1000);
	//read results
	float * output = (float*) malloc(sizeof(float)*globalWorkSize);
	status = clEnqueueReadBuffer(commandQueue, outputBuffer, CL_TRUE,0,
                                 globalWorkSize * sizeof(cl_float),output,
                                 0,NULL,NULL);
	status = clFlush(commandQueue);
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
	avg /= (globalWorkSize*count);
	float stdDev = 0.0f;
	if(count == 1) {
		//standard deviation
		for(int i = 0;i < globalWorkSize;++i) {
			stdDev += pow(output[i] - avg,2);
		}
		stdDev /= (globalWorkSize*count);
	}
	printf("Processing %d samples in %d iterations.\n Time %f seconds.\n Average value: %f.\n",globalWorkSize,NUMBER_OF_ITERATIONS,((float)(second-first))/1000.0f,avg);
	if(count == 1){ 
		printf("Standard deviation %f.\n Min %f.\n Max %f.\n",stdDev,min,max);
	}
	//clean up!
	free(output);
	free(devices);
	clReleaseKernel(kernel);
	clReleaseMemObject(outputBuffer);
 	clReleaseProgram(program);
	clReleaseCommandQueue(commandQueue);
	clReleaseContext(context);
	return 0;
}

