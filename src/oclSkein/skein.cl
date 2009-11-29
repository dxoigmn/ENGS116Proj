/***********************************************************************
**
** Implementation of the AHS API using the Skein hash function.
**
** Source code author: Doug Whiting, 2008.
**
** This algorithm and source code is released to the public domain.
** 
************************************************************************/

#include <string.h>

/******************************************************************/
/*     AHS API code                                               */
/******************************************************************/

#define  SKEIN_MODIFIER_WORDS  ( 2)          /* number of modifier (tweak) words */

#define SKEIN_512_ROUNDS_TOTAL (72)
#define SKEIN_512_STATE_WORDS (8)
#define SKEIN_512_STATE_BYTES ( 8*SKEIN_512_STATE_WORDS)
#define SKEIN_512_STATE_BITS  (64*SKEIN_512_STATE_WORDS)
#define SKEIN_512_BLOCK_BYTES ( 8*SKEIN_512_STATE_WORDS)

#define SKEIN_MK_64(hi32,lo32)  ((lo32) + (((unsigned long) (hi32)) << 32))

#define SKEIN_VERSION           (1)
#define SKEIN_ID_STRING_LE      (0x33414853)            /* "SHA3" (little-endian)*/

#define SKEIN_SCHEMA_VER        SKEIN_MK_64(SKEIN_VERSION,SKEIN_ID_STRING_LE)
#define SKEIN_KS_PARITY         SKEIN_MK_64(0x55555555,0x55555555)

#define SKEIN_T1_BIT(BIT)       ((BIT) - 64)            /* offset 64 because it's the second word  */
                                
#define SKEIN_T1_POS_TREE_LVL   SKEIN_T1_BIT(112)       /* bits 112..118: level in hash tree       */
#define SKEIN_T1_POS_BIT_PAD    SKEIN_T1_BIT(119)       /* bit  119     : partial final input byte */
#define SKEIN_T1_POS_BLK_TYPE   SKEIN_T1_BIT(120)       /* bits 120..125: type field               */
#define SKEIN_T1_POS_FIRST      SKEIN_T1_BIT(126)       /* bits 126     : first block flag         */
#define SKEIN_T1_POS_FINAL      SKEIN_T1_BIT(127)       /* bit  127     : final block flag         */
                                
/* tweak word T[1]: flag bit definition(s) */
#define SKEIN_T1_FLAG_FIRST     (((unsigned long)  1 ) << SKEIN_T1_POS_FIRST)
#define SKEIN_T1_FLAG_FINAL     (((unsigned long)  1 ) << SKEIN_T1_POS_FINAL)
#define SKEIN_T1_FLAG_BIT_PAD   (((unsigned long)  1 ) << SKEIN_T1_POS_BIT_PAD)

/* tweak word T[1]: block type field */
#define SKEIN_BLK_TYPE_KEY      ( 0)                    /* key, for MAC and KDF */
#define SKEIN_BLK_TYPE_CFG      ( 4)                    /* configuration block */
#define SKEIN_BLK_TYPE_PERS     ( 8)                    /* personalization string */
#define SKEIN_BLK_TYPE_PK       (12)                    /* public key (for digital signature hashing) */
#define SKEIN_BLK_TYPE_KDF      (16)                    /* key identifier for KDF */
#define SKEIN_BLK_TYPE_NONCE    (20)                    /* nonce for PRNG */
#define SKEIN_BLK_TYPE_MSG      (48)                    /* message processing */
#define SKEIN_BLK_TYPE_OUT      (63)                    /* output stage */
#define SKEIN_BLK_TYPE_MASK     (63)                    /* bit field mask */

#define SKEIN_T1_BLK_TYPE(T)   (((unsigned long) (SKEIN_BLK_TYPE_##T)) << SKEIN_T1_POS_BLK_TYPE)
#define SKEIN_T1_BLK_TYPE_KEY   SKEIN_T1_BLK_TYPE(KEY)  /* key, for MAC and KDF */
#define SKEIN_T1_BLK_TYPE_CFG   SKEIN_T1_BLK_TYPE(CFG)  /* configuration block */
#define SKEIN_T1_BLK_TYPE_PERS  SKEIN_T1_BLK_TYPE(PERS) /* personalization string */
#define SKEIN_T1_BLK_TYPE_PK    SKEIN_T1_BLK_TYPE(PK)   /* public key (for digital signature hashing) */
#define SKEIN_T1_BLK_TYPE_KDF   SKEIN_T1_BLK_TYPE(KDF)  /* key identifier for KDF */
#define SKEIN_T1_BLK_TYPE_NONCE SKEIN_T1_BLK_TYPE(NONCE)/* nonce for PRNG */
#define SKEIN_T1_BLK_TYPE_MSG   SKEIN_T1_BLK_TYPE(MSG)  /* message processing */
#define SKEIN_T1_BLK_TYPE_OUT   SKEIN_T1_BLK_TYPE(OUT)  /* output stage */
#define SKEIN_T1_BLK_TYPE_MASK  SKEIN_T1_BLK_TYPE(MASK) /* field bit mask */

#define SKEIN_T1_BLK_TYPE_CFG_FINAL       (SKEIN_T1_BLK_TYPE_CFG | SKEIN_T1_FLAG_FINAL)
#define SKEIN_T1_BLK_TYPE_OUT_FINAL       (SKEIN_T1_BLK_TYPE_OUT | SKEIN_T1_FLAG_FINAL)

/* bit field definitions in config block treeInfo word */
#define SKEIN_CFG_TREE_LEAF_SIZE_POS  ( 0)
#define SKEIN_CFG_TREE_NODE_SIZE_POS  ( 8)
#define SKEIN_CFG_TREE_MAX_LEVEL_POS  (16)

#define SKEIN_CFG_TREE_LEAF_SIZE_MSK  (((unsigned long) 0xFF) << SKEIN_CFG_TREE_LEAF_SIZE_POS)
#define SKEIN_CFG_TREE_NODE_SIZE_MSK  (((unsigned long) 0xFF) << SKEIN_CFG_TREE_NODE_SIZE_POS)
#define SKEIN_CFG_TREE_MAX_LEVEL_MSK  (((unsigned long) 0xFF) << SKEIN_CFG_TREE_MAX_LEVEL_POS)

#define SKEIN_CFG_TREE_INFO(leaf,node,maxLvl)                   \
    ( (((unsigned long)(leaf  )) << SKEIN_CFG_TREE_LEAF_SIZE_POS) |    \
      (((unsigned long)(node  )) << SKEIN_CFG_TREE_NODE_SIZE_POS) |    \
      (((unsigned long)(maxLvl)) << SKEIN_CFG_TREE_MAX_LEVEL_POS) )

#define SKEIN_CFG_TREE_INFO_SEQUENTIAL SKEIN_CFG_TREE_INFO(0,0,0) /* use as treeInfo in InitExt() call for sequential processing */

#define SKEIN_CFG_STR_LEN       (4*8)

#define RotL_64(x,N) (x << (N & 63)) | (x >> ((64-N) & 63))

void Skein_512_Process_Block(unsigned long *_X, unsigned long *_T, const unsigned char *blkPtr, unsigned int blkCnt, unsigned int byteCntAdd)
{
    unsigned int  i,r,n;
    unsigned long  ts[3];                            /* key schedule: tweak */
    unsigned long  ks[SKEIN_512_STATE_WORDS+1];      /* key schedule: chaining vars */
    unsigned long  X [SKEIN_512_STATE_WORDS];        /* local copy of vars */
    unsigned long  w [SKEIN_512_STATE_WORDS];        /* local copy of input block */

    do  {
        /* this implementation only supports 2**64 input bytes (no carry out here) */
        _T[0] += byteCntAdd;            /* update processed length */

        /* precompute the key schedule for this block */
        ks[SKEIN_512_STATE_WORDS] = SKEIN_KS_PARITY;
        for (i=0;i < SKEIN_512_STATE_WORDS; i++) {
            ks[i]     = _X[i];
            ks[SKEIN_512_STATE_WORDS] ^= _X[i];            /* compute overall parity */
        }
        
        ts[0] = _T[0];
        ts[1] = _T[1];
        ts[2] = ts[0] ^ ts[1];

        //Skein_Get64_LSB_First(w, blkPtr, SKEIN_512_STATE_WORDS); /* get input block in little-endian format */
        for (n=0;n<8*SKEIN_512_STATE_WORDS;n+=8) {
            w[n/8] = (((unsigned long) blkPtr[n  ])      ) +
                     (((unsigned long) blkPtr[n+1]) <<  8) +
                     (((unsigned long) blkPtr[n+2]) << 16) +
                     (((unsigned long) blkPtr[n+3]) << 24) +
                     (((unsigned long) blkPtr[n+4]) << 32) +
                     (((unsigned long) blkPtr[n+5]) << 40) +
                     (((unsigned long) blkPtr[n+6]) << 48) +
                     (((unsigned long) blkPtr[n+7]) << 56) ;
        }

        for (i=0;i < SKEIN_512_STATE_WORDS; i++) {               /* do the first full key injection */
            X[i]  = w[i] + ks[i];
        }

        X[SKEIN_512_STATE_WORDS-3] += ts[0];
        X[SKEIN_512_STATE_WORDS-2] += ts[1];

        for (r=1;r <= SKEIN_512_ROUNDS_TOTAL/8; r++) { /* unroll 8 rounds */
            X[0] += X[1]; X[1] = RotL_64(X[1],46); X[1] ^= X[0];
            X[2] += X[3]; X[3] = RotL_64(X[3],36); X[3] ^= X[2];
            X[4] += X[5]; X[5] = RotL_64(X[5],19); X[5] ^= X[4];
            X[6] += X[7]; X[7] = RotL_64(X[7],37); X[7] ^= X[6];

            X[2] += X[1]; X[1] = RotL_64(X[1],33); X[1] ^= X[2];
            X[4] += X[7]; X[7] = RotL_64(X[7],27); X[7] ^= X[4];
            X[6] += X[5]; X[5] = RotL_64(X[5],14); X[5] ^= X[6];
            X[0] += X[3]; X[3] = RotL_64(X[3],42); X[3] ^= X[0];

            X[4] += X[1]; X[1] = RotL_64(X[1],17); X[1] ^= X[4];
            X[6] += X[3]; X[3] = RotL_64(X[3],49); X[3] ^= X[6];
            X[0] += X[5]; X[5] = RotL_64(X[5],36); X[5] ^= X[0];
            X[2] += X[7]; X[7] = RotL_64(X[7],39); X[7] ^= X[2];

            X[6] += X[1]; X[1] = RotL_64(X[1],44); X[1] ^= X[6];
            X[0] += X[7]; X[7] = RotL_64(X[7], 9); X[7] ^= X[0];
            X[2] += X[5]; X[5] = RotL_64(X[5],54); X[5] ^= X[2];
            X[4] += X[3]; X[3] = RotL_64(X[3],56); X[3] ^= X[4];

            for (i=0;i < SKEIN_512_STATE_WORDS;i++) {
                 X[i] += ks[((2*r-1)+i) % (SKEIN_512_STATE_WORDS+1)];
            }

            X[SKEIN_512_STATE_WORDS-3] += ts[((2*r-1)+0) % 3];
            X[SKEIN_512_STATE_WORDS-2] += ts[((2*r-1)+1) % 3];
            X[SKEIN_512_STATE_WORDS-1] += (2*r-1);

            X[0] += X[1]; X[1] = RotL_64(X[1],39); X[1] ^= X[0];
            X[2] += X[3]; X[3] = RotL_64(X[3],30); X[3] ^= X[2];
            X[4] += X[5]; X[5] = RotL_64(X[5],34); X[5] ^= X[4];
            X[6] += X[7]; X[7] = RotL_64(X[7],24); X[7] ^= X[6];

            X[2] += X[1]; X[1] = RotL_64(X[1],13); X[1] ^= X[2];
            X[4] += X[7]; X[7] = RotL_64(X[7],50); X[7] ^= X[4];
            X[6] += X[5]; X[5] = RotL_64(X[5],10); X[5] ^= X[6];
            X[0] += X[3]; X[3] = RotL_64(X[3],17); X[3] ^= X[0];

            X[4] += X[1]; X[1] = RotL_64(X[1],25); X[1] ^= X[4];
            X[6] += X[3]; X[3] = RotL_64(X[3],29); X[3] ^= X[6];
            X[0] += X[5]; X[5] = RotL_64(X[5],39); X[5] ^= X[0];
            X[2] += X[7]; X[7] = RotL_64(X[7],43); X[7] ^= X[2];

            X[6] += X[1]; X[1] = RotL_64(X[1], 8); X[1] ^= X[6];
            X[0] += X[7]; X[7] = RotL_64(X[7],35); X[7] ^= X[0];
            X[2] += X[5]; X[5] = RotL_64(X[5],56); X[5] ^= X[2];
            X[4] += X[3]; X[3] = RotL_64(X[3],22); X[3] ^= X[4];
            
            for (i=0;i < SKEIN_512_STATE_WORDS;i++) {
                 X[i] += ks[((2*r)+i) % (SKEIN_512_STATE_WORDS+1)];
            }

            X[SKEIN_512_STATE_WORDS-3] += ts[((2*r)+0) % 3];
            X[SKEIN_512_STATE_WORDS-2] += ts[((2*r)+1) % 3];
            X[SKEIN_512_STATE_WORDS-1] += (2*r);                    /* avoid slide attacks */
        }

        /* do the final "feedforward" xor, update context chaining vars */
        for (i=0;i < SKEIN_512_STATE_WORDS;i++) {
            _X[i] = X[i] ^ w[i];
        }

        _T[1] &= ~(((unsigned long)  1 ) << ((126) - 64));    /* clear the start bit */
        blkPtr += SKEIN_512_BLOCK_BYTES;
    } while (--blkCnt);
}

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* all-in-one hash function */
__kernel int Hash(__global unsigned int *hashbitlen, __global const unsigned char *data, __global unsigned int *databitlen, __global unsigned char *hashval)
{
    unsigned int  bCnt = 0;
    unsigned char b[SKEIN_512_BLOCK_BYTES];
    unsigned long X[SKEIN_512_STATE_WORDS];
    unsigned long T[SKEIN_MODIFIER_WORDS];
    
    //Init(&bCnt, X, T, hashbitlen);
    //unsigned int Init(unsigned int *bCnt, unsigned long *_X, unsigned long *_T, int hashBitLen)
    {
        union {
          unsigned char  b[SKEIN_512_STATE_BYTES];
          unsigned long  w[SKEIN_512_STATE_WORDS];
        } cfg;                                  /* config block */

        /* set tweaks: T0=0; T1=CFG | FINAL */
        T[0] = 0;
        T[1] = SKEIN_T1_FLAG_FIRST | SKEIN_T1_BLK_TYPE_CFG_FINAL;

        memset(&cfg.w, 0, sizeof(cfg.w));             /* pre-pad cfg.w[] with zeroes */
        cfg.w[0] = SKEIN_SCHEMA_VER;                  /* set the schema, version */
        cfg.w[1] = *hashbitlen;                       /* hash result length in bits */
        cfg.w[2] = SKEIN_CFG_TREE_INFO_SEQUENTIAL;

        /* compute the initial chaining values from config block */
        memset(X, 0, SKEIN_512_STATE_WORDS * sizeof(unsigned long));  /* zero the chaining variables */
        Skein_512_Process_Block(X, T, cfg.b, 1, SKEIN_CFG_STR_LEN);

        /* The chaining vars ctx->X are now initialized for the given hashbitlen. */
        /* Set up to process the data message portion of the hash (default) */
        T[0] = 0;
        T[1] = SKEIN_T1_FLAG_FIRST | SKEIN_T1_BLK_TYPE_MSG;
        bCnt = 0;
        
        //return 0;
    }
    
    //Update(&bCnt, b, X, T, data, databitlen);
    //int Update(unsigned int *bCnt, unsigned char *b, unsigned long *X, unsigned long *T, const unsigned char *data, unsigned long long databitlen)
    {
        unsigned int n;
        unsigned char *msg = (unsigned char *)data;
        unsigned int msgByteCnt = *databitlen >> 3;

        /* process full blocks, if any */
        if (msgByteCnt + bCnt > SKEIN_512_BLOCK_BYTES) {
            if (bCnt) {                              /* finish up any buffered message data */
                n = SKEIN_512_BLOCK_BYTES - bCnt;  /* # bytes free in buffer b[] */
                if (n) {
                    memcpy(&b[bCnt], msg, n);
                    msgByteCnt  -= n;
                    msg         += n;
                    bCnt        += n;
                }

                Skein_512_Process_Block(X, T, b, 1, SKEIN_512_BLOCK_BYTES);
                bCnt = 0;
            }

            /* now process any remaining full blocks, directly from input message data */
            if (msgByteCnt > SKEIN_512_BLOCK_BYTES) {
                n = (msgByteCnt-1) / SKEIN_512_BLOCK_BYTES;   /* number of full blocks to process */
                Skein_512_Process_Block(X, T, msg, n, SKEIN_512_BLOCK_BYTES);
                msgByteCnt -= n * SKEIN_512_BLOCK_BYTES;
                msg        += n * SKEIN_512_BLOCK_BYTES;
            }
        }

        /* copy any remaining source message data bytes into b[] */
        if (msgByteCnt) {
            memcpy(&b[bCnt], msg, msgByteCnt);
            bCnt += msgByteCnt;
        }

        //return 0;
    }
    
    //Final(&bCnt, b, X, T, hashbitlen, hashval);
    //int Final(unsigned int *bCnt, unsigned char *b, unsigned long *_X, unsigned long *T, int hashBitLen, unsigned char *hashVal)
    {
        unsigned int i,n,byteCnt;
        unsigned long _X[SKEIN_512_STATE_WORDS];

        T[1] |= SKEIN_T1_FLAG_FINAL;                  /* tag as the final block */
        if (bCnt < SKEIN_512_BLOCK_BYTES) {          /* zero pad b[] if necessary */
            memset(&b[bCnt], 0, SKEIN_512_BLOCK_BYTES - bCnt);
        }

        Skein_512_Process_Block(X, T, b, 1, bCnt);  /* process the final block */

        /* now output the result */
        byteCnt = (*hashbitlen + 7) >> 3;             /* total number of output bytes */

        /* run Threefish in "counter mode" to generate more output */
        memset(b, 0 , SKEIN_512_BLOCK_BYTES);  /* zero out b[], so it can hold the counter */
        memcpy(_X, X, SKEIN_512_STATE_WORDS * sizeof(unsigned long));       /* keep a local copy of counter mode "key" */

        for (i=0;i*SKEIN_512_BLOCK_BYTES < byteCnt;i++) {
            ((unsigned long *)b)[0]= ((unsigned long) i); /* build the counter block */
            T[0] = 0;
            T[1] = SKEIN_T1_FLAG_FIRST | SKEIN_T1_BLK_TYPE_OUT_FINAL;
            bCnt = 0;

            Skein_512_Process_Block(X, T, b, 1, sizeof(unsigned long)); /* run "counter mode" */

            n = byteCnt - i*SKEIN_512_BLOCK_BYTES;   /* number of output bytes left to go */
            if (n >= SKEIN_512_BLOCK_BYTES) {
                n  = SKEIN_512_BLOCK_BYTES;
            }

            unsigned int m;
            __global unsigned char *dst = hashval+i*SKEIN_512_BLOCK_BYTES;
            unsigned long *src = X;

            for (m=0;m<n;m++) {
                dst[m] = (unsigned char) (src[m>>3] >> (8*(m&7)));
            }

            memcpy(X, _X, SKEIN_512_STATE_WORDS * sizeof(unsigned long));   /* restore the counter mode key for next time */
        }

        //return 0;
    }
    return 0;
}
