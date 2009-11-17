#if defined(__APPLE__)
#if _GLIBCXX_ATOMIC_BUILTINS == 1
#undef _GLIBCXX_ATOMIC_BUILTINS
#endif // _GLIBCXX_ATOMIC_BUILTINS
#endif // __APPLE__

#include <iostream>
#include <stdio.h>
#include <cutil.h>
#include <vector>
#include <string>

/*
 * Copyright (c) 2009 Steve Worley < m a t h g e e k@(my last name).com >
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */


/* SHA 1  brute force searcher for EngineYard hash match challenge.
   Steve Worley, July 18, 2009

   See the challenge: 
    http://www.engineyard.com/blog/2009/programming-contest-win-iphone-3gs-2k-cloud-credit/

   Discussion online on the NVidia CUDA pages!
   http://forums.nvidia.com/index.php?showtopic=102349


   Version 0.15. Check the forum post above for updates!

   Change history:
   
   v 0.16
      Now deletes timer
      -blocksize command line option for static block size

   v 0.15
      Detect if we're on G200 or not. On G200, we can use 192 threads. On G80/G90 we
      use a less efficient 128 threads.  CUDA 2.2 is way too register hungry!
   
   v 0.14
      Forum reminder printout for actual users
      Thread setting put at top of code (set to 128 to run with CUDA 2.2 and G80/G90)
      Rearranged first and third SHA f computes to save a clock on each

   v 0.13
      gcc compiler warning cleanups
      free memory at end of string search (slow leak of device mem)
      use a parallel reduction to find block best. 1% speedup.

   v 0.12 
      Now does a pre-hashed constant block to allow strings >64 characters. 
        In fact this is a requirement. This allows 12 words to be chosen.
      Updated hash speed, v11 didn't change computation for smaller block sizes
      5% speed boost by making simpler case for final 16 rounds where popping w[] is easier
      THIS CODE IS NOW USABLE FOR THE CONTEST. It's likely not final, but it will work!
      
   v 0.11: 
     added missing std:: prefix to vector and string for GCC
     Threads only iterate over 64*64 characters, not 93*93, to make smaller block work size
     #pragma unroll on the inner loops
     Now actually sets the device for multi-GPU
     KNOWN ISSUE: Still needs to pick only 12 prefix rules 

   v 0.10: 
     initial version


   PLEASE contribute to the code if you have ideas, optimizations or bugfixes.

   Yes, this means that if you win the contest, you can keep the EngineYard prize!
   But please TELL US by posting to the forum!


   Compile on windows with a line similar to:
      nvcc -I "E:\CUDA\common\inc"  gpusha1.cu  e:\cuda\common\lib\cutil32.lib -o gpusha1search.exe


   run with a commandline like:
         gpusha1search.exe -device 0 -blocksize 400 6cac827bae250971a8b1fb6e2a96676f7a077b60 Cloud Ruby DHH one eight six active record controller data rspec mongrel MySQL postgresSQL tokyo MRI jruby rubinius memcached exception metaprogramming reflection


   You can check the SHA1 hash of both the challenge and resulting best phrase with any SHA1 
   computation. A nice cut-and-paste one online is:
         http://sha1-hash-online.waraxe.us/

*/


/* For best performance, use 192 threads. But CUDA 2.2 and 2.3 compile this with huge 
   register use, causing kernel launch failures on G80 and G90 hardware.
   This can be avoided by compiling with CUDA 2.0, or reducing the line below to 
   be 128 threads. */

int threads=192;



int staticblocksize=0; // use dynamic block sizes by default


#ifdef __DEVICE_EMULATION__
#define debugprint printf
#define EMUSYNC __syncthreads()
#else
__device__ void NOOPfunction(char *format) {}
__device__ void NOOPfunction(char *format, unsigned int onearg) {}
__device__ void NOOPfunction(char *format, unsigned int onearg, unsigned int twoargs) {}
__device__ void NOOPfunction(char *format, char *onearg) {}
#define EMUSYNC do {} while (0)
#define debugprint NOOPfunction
#endif


__shared__ unsigned int keyString[16];
__shared__ unsigned int goalHash[5];
__shared__ unsigned int initVector[5];



/* extra complexity since SHA uses big-endian computes but x86 and CUDA use little-endian.
   We need to flip the words. But this will also flip the per-thread destination indices! */

__shared__ int firstCharIndex; // first character each thread can permute
__shared__ int secondCharIndex; // second character each thread can permute


__host__ __device__ unsigned int swapends(unsigned int v) 
{
  return 
    ((255&(v>> 0))<<24)+
    ((255&(v>> 8))<<16)+
    ((255&(v>>16))<<8)+
    ((255&(v>>24))<<0);
}

// when a byte index into a word array is word flipped for endianness, what's our new index?
__device__ unsigned int swappedIndex(int v)
{
  int remainder=v&3;
  return (v&0xFFFFFFFC)+(3-remainder);
}

__device__ void initStringAndGoal(const unsigned int *deviceKeystring,
				  int stringLength,  
				  int blockIndex,
				  const unsigned int *deviceInitVector,
				  const unsigned int *deviceGoalHash)
{
  char *charkeyString=(char *)keyString; // just for convienience

  if (threadIdx.x<16)
    keyString[threadIdx.x]=deviceKeystring[threadIdx.x];

  if (threadIdx.x<5) {    
    initVector[threadIdx.x]=deviceInitVector[threadIdx.x];
    goalHash[threadIdx.x]=deviceGoalHash[threadIdx.x];
  }
  
  EMUSYNC;
  
  if (threadIdx.x==0) {
    
    charkeyString[stringLength]=' '; // one space before our 5 characters
    
    // There are 93 printable ASCII chars (skipping space).
    // index is really three digits of a radix 93 number.
    // we initialize the first three chars based on this three digit number. 
    int c=blockIndex/(93*93);
    charkeyString[stringLength+1]= (char)(33+c); // 33 is first ASCII char, "!"

    blockIndex-=c*93*93;
    c=blockIndex/93;
    charkeyString[stringLength+2]= (char)(33+c);
    blockIndex-=c*93;
    c=blockIndex;
    charkeyString[stringLength+3]= (char)(33+c);

    /* chars 4, 5 will be set by individual threads in their own copies */
    
    charkeyString[stringLength+6]=(char)128; // SHA1 sets first non-data bit to '1'
    keyString[15]=512+8*(stringLength+6); // Length of string, +1 for space, +5 for appended chars

    // after big-endian flipping, which index do our two changable characters end up at?
    firstCharIndex=swappedIndex(stringLength+4);
    secondCharIndex=swappedIndex(stringLength+5);       
  }
  
  __syncthreads();
  
  //  if (threadIdx.x==0) 
  //    for (int i=0; i<16; i++) debugprint("M%ld %08x\n", i, keyString[i]);
  
  if (threadIdx.x<15)
    keyString[threadIdx.x]=swapends(keyString[threadIdx.x]);
 
  __syncthreads();
  
  //  for (int i=0; i<16; i++) debugprint("S%ld %08x\n", i, keyString[i]);
}


__device__ void prepareString(int trialIndex, int stringLength)
{
  extern __shared__ unsigned int fullw[];
  unsigned int *w=fullw+17*threadIdx.x; // spaced by 17 to avoid bank conflicts

  for (int i=0; i<16; ++i) w[i]=keyString[i];
  
  int c=trialIndex>>6; // 0 to 64
  ((char *)w)[firstCharIndex]=(char)(33+c);
  c=trialIndex&63;
  ((char *)w)[secondCharIndex]= (char)(33+c);

  //  if (threadIdx.x==0) debugprint("testing string -%s-\n", (char *)w);
}


/* We don't want to precompute and store all 80 w array
   values. Instead we store only the next 16 values and update them in
   a logrolling array. Complicated but it means we can fit the tables
   in shared memory */
__device__ unsigned int popNextW(unsigned int *w, int &wIndex)
{
  unsigned int nextW=w[wIndex&15];
  int thisIndex=wIndex&15;
  w[thisIndex]^=w[(wIndex+16-3)&15]^w[(wIndex+16-8)&15]^w[(wIndex+16-14)&15];
  w[thisIndex]=  (w[thisIndex]<<1) | (w[thisIndex]>>31);
  ++wIndex;

  //  if (threadIdx.x==0) debugprint("pop %08x\n", nextW);
  return nextW;
}

/* same as above but we don't need to compute more of the table  at the end. */
__device__ unsigned int popFinalWs(unsigned int *w, int &wIndex)
{
  unsigned int nextW=w[wIndex&15];
  ++wIndex;
  return nextW;
}



__device__ int computeSHAscore()
{
  extern __shared__ unsigned int fullw[];
  unsigned int *w=fullw+17*threadIdx.x; // spaced by 17 to avoid bank conflicts
  int wIndex=0;


  //  if (threadIdx.x==0) debugprint("-%s-\n", (char *)w);

  /* SHA algorithm. See
   http://en.wikipedia.org/wiki/SHA_hash_functions.  Big
   implementation difference is we use a rolling 16-entry table for the w[]
   array to save precious shared memory space */

  unsigned int a = initVector[0];
  unsigned int b = initVector[1];
  unsigned int c = initVector[2];
  unsigned int d = initVector[3];
  unsigned int e = initVector[4];

#pragma unroll 999
  for (int i=0; i<20; ++i) {
    unsigned int thisW=popNextW(w, wIndex);
    //    unsigned int f= (b&c)|((~b)&d);
    unsigned int f= d ^ (b & (c^d)); // alternate computation of above
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x5A827999+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

#pragma unroll 999
  for (int i=20; i<40; ++i) {
    unsigned int thisW=popNextW(w, wIndex);
    unsigned int f= b^c^d;
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x6ED9EBA1+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

#pragma unroll 999
  for (int i=40; i<60; ++i) {
    unsigned int thisW=popNextW(w, wIndex);
    //    unsigned int f= (b&c) | (b&d) | (c&d);
    unsigned int f= (b&c) | (d & (b|c)); // alternate computation of above
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x8F1BBCDC+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

#pragma unroll 999
  for (int i=60; i<64; ++i) {
    unsigned int thisW=popNextW(w, wIndex);
    unsigned int f= b^c^d;
    unsigned int temp=((a<<5)|(a>>27))+f+e+0xCA62C1D6+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }


#pragma unroll 999
  for (int i=64; i<80; ++i) {
    unsigned int thisW=popFinalWs(w, wIndex); // simpler compute for final rounds
    unsigned int f= b^c^d;
    unsigned int temp=((a<<5)|(a>>27))+f+e+0xCA62C1D6+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

  a+= initVector[0];
  b+= initVector[1];
  c+= initVector[2];
  d+= initVector[3];
  e+= initVector[4];

  /* the SHA hash is now a b c d e (concatinated) */

  //  if (threadIdx.x==0) debugprint("Hash= %08x %08x, %08x", a, b, c);
 

  /* xor with goal hash. Score is just summed population count. */

  int score=__popc(a^goalHash[0]) + 
    __popc(b^goalHash[1])+ +
    __popc(c^goalHash[2]) + 
    __popc(d^goalHash[3]) + 
    __popc(e^goalHash[4]); 

  return score;
}

__device__ void testSHA(int trialIndex, int stringLength, int &bestScore, int &bestIndex)
{
  prepareString(trialIndex, stringLength);
  int score=computeSHAscore();
  if (score<bestScore) {
    bestScore=score;
    bestIndex=trialIndex;
  }
}

__device__ void reportResultOfBestThread(int index, int score, unsigned int *bestarray)
{
  extern __shared__ unsigned int w[];

  /* each thread concatinates its best score with its best index */  
  w[threadIdx.x]= (score<<24)+index;
  __syncthreads();
  

  
  // I'm assuming blockdim.x< 256 here
  if (threadIdx.x+128< blockDim.x) w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+128]);
  __syncthreads();  
  
  if (threadIdx.x<64 && threadIdx.x+64< blockDim.x) w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+64]);
  __syncthreads();  

  if (threadIdx.x<32) { // no need for syncthreads in a single warp
    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+32]); 
    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+16]); 
    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+8]); 
    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+4]); 
    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+2]); 
    //    w[threadIdx.x]=min(w[threadIdx.x], w[threadIdx.x+1]); 
  }
  
  if (threadIdx.x==0) bestarray[blockIdx.x]=min(w[0], w[1]);

}



/* Given a fixed string like "Rubinius one eight" with length LESS
   THAN 50 CHARACTERS, an 8-word goal hash value, and an absolute
   block number from 0 to 93*93*93-1=804356.  Evaluate all the possible appended 5
   character substrings (with first three characters enumerated over the
   given block range given by the starting number and the kernel's
   block count, last 2 characters enumerated over all 93^2
   possibilities).  Return value is an array of each blocks's local best result,
   which likely should be searched on the CPU for the minimum.

   The input keystring is loaded as 8 words. Pad your string at the end with 0s to populate it to
   16 words.
 */   

__global__ void sha1search(const unsigned int *deviceKeystring, 
			   int stringLength, 
			   const unsigned int *deviceInitVector, 
			   const unsigned int *deviceGoalHash, 
			   int blockIndexOffset, /* 0..93*93*93-1 */
			   unsigned int *bestarray)
{ 
  if (blockIndexOffset+blockIdx.x>=93*93*93) { // end of work
    bestarray[blockIdx.x]=0xFFFFFFFF;
    return;
  }

  initStringAndGoal(deviceKeystring, stringLength, blockIndexOffset+blockIdx.x, 
		    deviceInitVector, deviceGoalHash);

  int perThreadBestScore=9999;
  int perThreadBestIndex=0;
  int trialindex=threadIdx.x;

  while (trialindex<64*64) {   // iterate over the 4K  test hash strings
    testSHA(trialindex, stringLength, perThreadBestScore, perThreadBestIndex);    
    trialindex+=blockDim.x; 
  }
  
  __syncthreads(); // let all threads finish their looped work
  
  reportResultOfBestThread(perThreadBestIndex, perThreadBestScore, bestarray);
}


unsigned int initPopNextW(unsigned int *w, int &wIndex) 
{
  return w[wIndex++];
}


void initHash(const char *baseString, unsigned int h_InitVector[5])
{
  unsigned int w[80]={0};
  int wIndex=0;
  strncpy((char *)w, baseString, 512/8); 

  for (int i=0; i<16; i++) w[i]=swapends(w[i]);

  for (int i=16; i<80; i++) {
    w[i]=w[i-3]^w[i-8]^w[i-14]^w[i-16];
    w[i]=(w[i]<<1)|(w[i]>>31);
  }
	

  unsigned int a = 0x67452301;
  unsigned int b = 0xEFCDAB89;
  unsigned int c = 0x98BADCFE;
  unsigned int d = 0x10325476;
  unsigned int e = 0xC3D2E1F0;

  for (int i=0; i<20; ++i) {
    unsigned int thisW=initPopNextW(w, wIndex);
    unsigned int f= (b&c)|((~b)&d);
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x5A827999+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

  for (int i=20; i<40; ++i) {
    unsigned int thisW=initPopNextW(w, wIndex);
    unsigned int f= b^c^d;
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x6ED9EBA1+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

  for (int i=40; i<60; ++i) {
    unsigned int thisW=initPopNextW(w, wIndex);
    unsigned int f= (b&c) | (b&d) | (c&d);
    unsigned int temp=((a<<5)|(a>>27))+f+e+0x8F1BBCDC+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

  
  for (int i=60; i<80; ++i) {
    unsigned int thisW=initPopNextW(w, wIndex);
    unsigned int f= b^c^d;
    unsigned int temp=((a<<5)|(a>>27))+f+e+0xCA62C1D6+thisW;
    e=d;
    d=c;
    c=(b<<30)|(b>>2);
    b=a;
    a=temp;
  }

  a+= 0x67452301;
  b+= 0xEFCDAB89;
  c+= 0x98BADCFE;
  d+= 0x10325476;
  e+= 0xC3D2E1F0;

  h_InitVector[0] = a;
  h_InitVector[1] = b;
  h_InitVector[2] = c;
  h_InitVector[3] = d;
  h_InitVector[4] = e;

}


void searchSHAWithBaseString(const char *baseString,
			     const unsigned int h_GoalHash[5],
			     int &bestScore,
			     char *bestString)
{
  unsigned int h_Keystring[16]={0};
  unsigned int h_InitVector[5]={0};
  unsigned int *d_Keystring;
  const int maxBlocks=5000;
  unsigned int  h_Best[maxBlocks];
  unsigned int  *d_GoalHash;
  unsigned int  *d_InitVector;
  unsigned int  *d_Best;
  int blocksPerKernelCall=10; // we'll dynamically ramp this up to aim for 40ms kernels
  int startblock=0;
  int lastPrintTime=0;
  int forumReminder=0;
  unsigned int timer = 0;
  int stringlength=strlen(baseString)-64; // we don't count the first block's!
  CUT_SAFE_CALL( cutCreateTimer( &timer));

  sprintf((char *)h_Keystring, baseString+64); // skip over first (constant) chunk

  CUDA_SAFE_CALL( cudaMalloc((void**)&d_Keystring, 16*32 ));
  CUDA_SAFE_CALL( cudaMalloc((void**)&d_GoalHash, 5*32 ));
  CUDA_SAFE_CALL( cudaMalloc((void**)&d_InitVector, 5*32 ));
  CUDA_SAFE_CALL( cudaMalloc((void**)&d_Best, maxBlocks*32 ));
	
  initHash(baseString, h_InitVector); // do SHA1 hash of first (constant) block
  
  CUDA_SAFE_CALL( cudaMemcpy( d_Keystring, h_Keystring, 16*32, cudaMemcpyHostToDevice) );
  CUDA_SAFE_CALL( cudaMemcpy( d_GoalHash, h_GoalHash, 5*32, cudaMemcpyHostToDevice) );
  CUDA_SAFE_CALL( cudaMemcpy( d_InitVector, h_InitVector, 5*32, cudaMemcpyHostToDevice) );


  while (startblock<93*93*93) {
    CUT_SAFE_CALL( cutResetTimer( timer));
    CUT_SAFE_CALL( cutStartTimer( timer));

    if (staticblocksize>0) blocksPerKernelCall=staticblocksize;

    if (startblock+blocksPerKernelCall>93*93*93)
      blocksPerKernelCall=93*93*93-startblock; // don't go past end

    sha1search<<<blocksPerKernelCall, threads, threads*17*4>>>(d_Keystring, stringlength,
							       d_InitVector, 
							       d_GoalHash, 
							       startblock, 
							       d_Best);    
    CUDA_SAFE_CALL( cudaMemcpy( &h_Best, d_Best, blocksPerKernelCall*sizeof(unsigned int), 
				cudaMemcpyDeviceToHost) );
    CUT_SAFE_CALL( cutStopTimer( timer));
    
    float duration=cutGetTimerValue( timer);
   
    int bestblock=0;
    for (int i=1; i<blocksPerKernelCall; i++) if (h_Best[i]<h_Best[0]) {
	h_Best[0]=h_Best[i];
	bestblock=i;
      }
    
    int bestindex=h_Best[0]&0x00FFFFFF;
    bestblock+=startblock;
    
    if (h_Best[0]>>24 < bestScore) { // global best!
      bestScore=h_Best[0]>>24;
      sprintf(bestString, "%s %c%c%c%c%c",
	      baseString,
	      33+((bestblock/(93*93))%93),
	      33+((bestblock/93)%93),
	      33+((bestblock)%93),
	      33+((bestindex>>6)),
	      33+(bestindex&63));
    }
    
    int thistime=time(NULL);
    if (thistime>lastPrintTime+5) {
      lastPrintTime=thistime;

    printf( "Processing time: %d blocks in %0.2f ms. %0.3f megahashes/sec\n", 
	    blocksPerKernelCall, duration, 64*64*0.001*blocksPerKernelCall/duration);
 
      printf("  Best score for this pass is %d, block %d, index %d\n", 
	     h_Best[0]>>24, 
	     bestblock,
	     bestindex);
      
      printf("  %s %c%c%c%c%c\n",
	     baseString,
	     33+((bestblock/(93*93))%93),
	     33+((bestblock/93)%93),
	     33+((bestblock)%93),
	     33+((bestindex>>6)),
	     33+(bestindex&63));
            
      printf("Best score: %d  with\n%s\n", bestScore, bestString);

      if (forumReminder==0)
	printf("\n\nThis code is provided for free.\nIf you win the SHA1 contest, congratulations, the prize is YOURS!\nYou don't need to share! But please also visit the CUDA forum\nwhere we discuss this tool, and report your progress and/or success.\nVisit  http://forums.nvidia.com/index.php?showtopic=102349 . Thanks!\nCrashing, invalid 0 score, or wild behavior? Update your NVIDIA card drivers to the latest stable release version.\n");
      forumReminder++;
      if (forumReminder>4) forumReminder=0;
    }
    
    startblock+=blocksPerKernelCall;
    const float goalDuration=30.0; // 30 milliseconds 
    if (duration<0.1*goalDuration)      blocksPerKernelCall=2*blocksPerKernelCall+1;
    else if (duration<1.0*goalDuration) blocksPerKernelCall++;
    else if (duration<1.5*goalDuration) blocksPerKernelCall-=3;
    else if (duration<3.0*goalDuration) blocksPerKernelCall/=2;
    else blocksPerKernelCall=1+0.01*blocksPerKernelCall;
    
    if (blocksPerKernelCall>maxBlocks) blocksPerKernelCall=maxBlocks;
    if (blocksPerKernelCall<4) blocksPerKernelCall=4;
  }

  CUDA_SAFE_CALL(cudaFree(d_Keystring));
  CUDA_SAFE_CALL(cudaFree(d_GoalHash));
  CUDA_SAFE_CALL(cudaFree(d_InitVector));
  CUDA_SAFE_CALL(cudaFree(d_Best));
  CUT_SAFE_CALL(cutDeleteTimer(timer));

}

void usage()
{
    std::cout << "gpusha1search -device 1 -blocksize 200 (40 hex digits of goal hash) word1 word2 word3 ..." << std::endl;
    std::cout << "example: gpusha1search -device 0 AB23456789AB23456789AB23456789AB23456789 apple banana carrot" << std::endl;
    exit(1);
}


int fromhex(char c)
{
  if (c>='0' && c<='9') return c-'0';
  if (c>='A' && c<='F') return c-'A'+10;
  if (c>='a' && c<='f') return c-'a'+10;
  return -1;  
}


/* I'm sure there must be a more clever way of doing this */
void parseHash(char *hash, unsigned int GoalHash[5])
{
  char *nextchar=hash;
  unsigned char *g=(unsigned char *)GoalHash;
  for (int i=0; i<20; i++) { // pull off two digits at a time
    int a=fromhex(*(nextchar++));
    int b=fromhex(*(nextchar++));
    if (a<0 || b<0) {
      printf("%s doesn't look like a 40 digit hex hash.\n", hash);
      exit(0);
    }
    *(g++)=16*a+b;
  }
  for (int i=0; i<5; i++) GoalHash[i]=swapends(GoalHash[i]);
}

void parseCmdLine(int argc, char **argv, unsigned int GoalHash[5], std::vector<std::string> &dict)
{
  int deviceCount;                                                        
  CUDA_SAFE_CALL_NO_SYNC(cudaGetDeviceCount(&deviceCount));                
  if (deviceCount == 0) {                                                  
    fprintf(stderr, "Error: no devices supporting CUDA found.\n");		
    exit(1);							
  }									

  int device=0;

  if (std::string("-device")==argv[1]) {
    device=atol(argv[2]);
    if (device<0) device=0;
    if (device>deviceCount-1) device=deviceCount-1;
    argv+=2;
    argc-=2;
  }


  if (std::string("-blocksize")==argv[1]) {
    staticblocksize=atol(argv[2]);
    argv+=2;
    argc-=2;
  }


  if (argc<3) {
    usage();
  }
  
  if (argc<14) {
    printf("You must enter at least 12 dictionary words.\n");
    usage();
  } 

  cudaDeviceProp deviceProp;                                               
  CUDA_SAFE_CALL_NO_SYNC(cudaGetDeviceProperties(&deviceProp, device));
  fprintf(stderr, "Using device %d: %s\n", device, deviceProp.name);

  if (deviceProp.major < 1) {                                              
    fprintf(stderr, "Error: device does not support CUDA.\n");     
    exit(EXIT_FAILURE);                                                  
  }                                                                        
  
  cudaSetDevice(device);
  
  // G200 has enough registers to run a full set of threads.
  // G80/G90 is register poor. CUDA 2.2 nvcc is too generous with register use,
  // but it does make faster code than CUDA 2.0
  if (deviceProp.regsPerBlock<10000) threads=128; else threads=192;

  parseHash(argv[1], GoalHash);
  
  for (int i=0; i<argc-2; ++i) 
    dict.push_back(argv[i+2]);

}

void randomPermute(unsigned int &seed, std::vector<std::string> &v)
{
  /* we COULD use the C++ random_shuffle here, but that's difficult to seed!
     It uses its own algorithm, and we want to add some time-based shuffle.
     So do a dumb set of random swaps. Not every permutation is equally likely,
     and the PRNG is not good, but it's more than enough for this kind of selection. */

  
  for (int i=0; i<v.size()-1; i++) {
    seed= 1103515245*seed+12345; // simple LCG
    unsigned int hashedseed=seed^(seed>>5)^(seed>>19)^(seed>>28);
    hashedseed*=0xDEADBEEF;
    hashedseed^=(hashedseed>>18);
    int swapindex=i+(hashedseed%(v.size()-i));
    std::swap(v[i], v[swapindex]);
  }
}

/* make a random selection of 12 keywords. */
/* NOTE FOR 0.11 this is WRONG for the contest, we need to make a two-block
   version to allow longer strings. This version is still valid but for speed testing.
*/

std::string GetRandomBaseString(unsigned int &seed, std::vector<std::string> &dict)
{
  std::string out;

  do {
    seed+=0xABCDEF;
    seed+=time(NULL);  
    
    randomPermute(seed, dict);   
    out=dict[0];
    for (int i=1; i<12; i++) out=out+" " +dict[i];
  } 
  while (out.length()<64 && out.length()>110);

  /* we're allowed to permute capitalization */
  for (int i=0; i<out.length(); i++) {
    seed= 1103515245*seed+12345; // simple LCG
    if (seed>>31) out[i]=toupper(out[i]);
    else out[i]=tolower(out[i]);
  }

  return out;
}

int main(int argc, char **argv) 
{
  char bestString[128]={0};
  int bestScore=999;
  unsigned int GoalHash[5]={0};
  unsigned int seed=time(NULL);
  std::vector<std::string> dict;
  
  if (argc<3) {
    usage();
  }

  parseCmdLine(argc, argv, GoalHash, dict);

  printf("\nSearching for hash %08x %08x %08x %08x %08x\n\nDictionary list:\n",
	 GoalHash[0], GoalHash[1], GoalHash[2], GoalHash[3], GoalHash[4]);

  for (int i=0; i<dict.size(); i++) std::cout << i << " " << dict[i] << std::endl;
  

  for (;;) {
    std::string base=GetRandomBaseString(seed, dict);
    std::cout << "Starting new pass with base string:" << base << std::endl;
    searchSHAWithBaseString(base.c_str(),
			    GoalHash,
			    bestScore, 
			    bestString);
  }
  
}
