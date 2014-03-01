#include "MT_local.hcl"
typedef char int8_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef short int16_t;
typedef unsigned int uint32_t;
typedef int int32_t;
typedef long int64_t;
typedef unsigned long uint64_t;

typedef struct _StateVector{
uint8_t d;
uint8_t s;
} StateVector;

typedef struct _PropertyState{
bool propertyState;
bool valueKnown;
} PropertyState;

__kernel void main( MT_state prngArg, uint32_t numberOfSimulations, uint32_t sampleNumber, __global float* pathLenghts) ;
uint8_t checkNonsynGuards( StateVector* sv, uint8_t* guardsTab) ;
void updateNonsynGuards( StateVector* sv, uint8_t* guardsTab, float selectionSum, uint8_t numberOfCommands) ;
bool checkProperties( StateVector* sv, PropertyState* propertyState) ;
__kernel void main( MT_state prngArg, uint32_t numberOfSimulations, uint32_t sampleNumber, __global float* results) {


uint16_t time = 0;
StateVector stateVector = {
0,
0
};
uint8_t selectionSize = 0;

PropertyState properties[1] = {
{ 0, 0 }
};
uint32_t globalID = get_global_id(0);
//printf("%d ",globalID);
float selection;
uint8_t guardsTab[8];
uint32_t i = 0L;
/*if(globalID >= numberOfSimulations) {
 return;
}*/
results[globalID + sampleNumber] = 100;
MT_init( rng, prngArg );
//if(globalID < 20)
//printf("first %f\n",MT_rndFloat(rng));
//float x = MT_rndFloat(rng);
for(i = 0;i < 100;++i){
selection = MT_rndFloat(rng);

selectionSize = checkNonsynGuards(&stateVector,guardsTab);

//selection = MT_rndFloat(rng)*selectionSize;
updateNonsynGuards(&stateVector,guardsTab,selection,selectionSize);

time++;

if(checkProperties(&stateVector,properties)){
break;
}
//checkProperties(&stateVector,properties);
/*
if(stateVector.s == 7){
for(int j = i;j < 100;++j)
selection = MT_rndFloat(rng);

break;
}*/
}
//printf(" -> %d %d\n",globalID+sampleNumber,time);
//int rndint = floor(MT_rndFloat(rng)*10);
//if(globalID < 20)
//printf("ending %d %d %d\n",globalID,sampleNumber,rndint);
//printf("%d\n",globalID);
//if(i != 100) {
//for(int j = i;j < 100;++j)
//selection = MT_rndFloat(rng);
//}
results[globalID + sampleNumber] = properties[0].propertyState;
//if(pathLenghts[globalID + sampleNumber] > 1)
//	printf("%d %d\n",globalID,pathLenghts[globalID + sampleNumber]);
MT_save(rng);
}


uint8_t checkNonsynGuards( StateVector* sv, uint8_t* guardsTab) {
uint8_t counter = 0;
if((*sv).s==0){
guardsTab[counter++] = 0;
}

if((*sv).s==1){
guardsTab[counter++] = 1;
}

if((*sv).s==2){
guardsTab[counter++] = 2;
}

if((*sv).s==3){
guardsTab[counter++] = 3;
}

if((*sv).s==4){
guardsTab[counter++] = 4;
}

if((*sv).s==5){
guardsTab[counter++] = 5;
}

if((*sv).s==6){
guardsTab[counter++] = 6;
}

if((*sv).s==7){
guardsTab[counter++] = 7;
}

if(counter != 8){
guardsTab[counter] = 8;
}

return counter;

}
void updateNonsynGuards( StateVector* sv, uint8_t* guardsTab, float selectionSum, uint8_t numberOfCommands) {
uint8_t selection = floor(selectionSum * numberOfCommands);
selection = floor(selectionSum);
selectionSum = numberOfCommands * (selectionSum - ((float)selection) / numberOfCommands);
selection = guardsTab[selection];
switch(selection){
case 0:
if(selectionSum < (0.5) ){
(*sv).s = 1;

}
else if(selectionSum < (1.0) ){
(*sv).s = 2;

}

break;
case 1:
if(selectionSum < (0.5) ){
(*sv).s = 3;

}
else if(selectionSum < (1.0) ){
(*sv).s = 4;

}

break;
case 2:
if(selectionSum < (0.5) ){
(*sv).s = 5;

}
else if(selectionSum < (1.0) ){
(*sv).s = 6;

}

break;
case 3:
if(selectionSum < (0.5) ){
(*sv).s = 1;

}
else if(selectionSum < (1.0) ){
(*sv).s = 7;
(*sv).d = 1;

}

break;
case 4:
if(selectionSum < (0.5) ){
(*sv).s = 7;
(*sv).d = 2;

}
else if(selectionSum < (1.0) ){
(*sv).s = 7;
(*sv).d = 3;

}

break;
case 5:
if(selectionSum < (0.5) ){
(*sv).s = 7;
(*sv).d = 4;

}
else if(selectionSum < (1.0) ){
(*sv).s = 7;
(*sv).d = 5;

}

break;
case 6:
if(selectionSum < (0.5) ){
(*sv).s = 2;

}
else if(selectionSum < (1.0) ){
(*sv).s = 7;
(*sv).d = 6;

}

break;
case 7:
(*sv).s = 7;

break;
}


}
bool checkProperties( StateVector* sv, PropertyState* propertyState) {
bool allKnown = 1;
bool counter;
if(!(propertyState[counter].valueKnown)){
allKnown = false;
if((*sv).s==7&&(*sv).d==6){
propertyState[counter].propertyState = true;
propertyState[counter].valueKnown = true;
}

}

return allKnown;

}
