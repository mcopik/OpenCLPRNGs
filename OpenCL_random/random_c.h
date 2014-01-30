#ifndef __CL_RANDOM_C_H
#define __CL_RANDOM_C_H

/**
 * @file random_c.h
 * 
 * @brief This header implements functions which allow the host-side initialization and management of OpenCL-pseudorandom number generators for a device.
 * 
 * @author Philipp Otterbein
 */


#include <CL/opencl.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include "aes/aes.c"
#include "shared/shared_consts.h"


#include "random_c/MersenneTwister.h"
#include "random_c/MTGP11213.h"
#include "random_c/Mother.h" 


#endif