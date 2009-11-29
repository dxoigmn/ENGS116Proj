/* echo.h */

/**********************************************************************************
 * Header file for the reference ansi C implementation of the ECHO hash
 * function proposal.
 * Author(s) : Gilles Macario-Rat - Orange Labs - October 2008.
 
 **********************************************************************************/

#ifndef __ECHO_H__
#define __ECHO_H__

typedef unsigned char		word8;	
typedef unsigned short		word16;	
typedef unsigned long		word32;
typedef unsigned char BitSequence;
typedef unsigned long long DataLength;
typedef enum { 
	SUCCESS=0
	,FAIL=1
	,BAD_HASHBITLEN=2
	,STATE_NULL=3
} HashReturn;


typedef struct {
	word8 tab [4][4][4][4];
	word8 tab_backup [4][4][4][4];
	word8 k1 [4][4];
	word8 k2 [4][4];
	word8 * Addresses[256];
	int index;
	int bit_index;
	int hashbitlen;
	int cv_size;
	int message_size;
	int messlenhi;
	int messlenlo;
	int counter_hi;
	int counter_lo;
	int rounds;
	int Computed;
} hashState;


HashReturn Init(hashState *state, int hashbitlen);

HashReturn Update(hashState *state,
                  const BitSequence *data, DataLength databitlen);

HashReturn Final(hashState *state, BitSequence *hashval);

HashReturn Hash(int hashbitlen, const BitSequence *data,
                DataLength databitlen, BitSequence *hashval);

void SetLevelTrace(int level);
HashReturn SetSalt(hashState *state, const BitSequence salt[16]);
#endif 
