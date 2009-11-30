/*
  Modified by Cory Cornelius from submitted "optimized" version of CubeHash 
  by Daniel J. Berstein as located at <http://cubehash.cr.yp.to/software.html>
*/

#define CUBEHASH_ROUNDS 16
#define CUBEHASH_BLOCKBYTES 32
#define ROTATE(a,b) (((a) << (b)) | ((a) >> (32 - b)))

static void transform(__global uint *x)
{
  int i;
  int r;
  uint y[16];

  for (r = 0;r < CUBEHASH_ROUNDS;++r) {
    for (i = 0;i < 16;++i) x[i + 16] += x[i];
    for (i = 0;i < 16;++i) y[i ^ 8] = x[i];
    for (i = 0;i < 16;++i) x[i] = ROTATE(y[i],7);
    for (i = 0;i < 16;++i) x[i] ^= x[i + 16];
    for (i = 0;i < 16;++i) y[i ^ 2] = x[i + 16];
    for (i = 0;i < 16;++i) x[i + 16] = y[i];
    for (i = 0;i < 16;++i) x[i + 16] += x[i];
    for (i = 0;i < 16;++i) y[i ^ 4] = x[i];
    for (i = 0;i < 16;++i) x[i] = ROTATE(y[i],11);
    for (i = 0;i < 16;++i) x[i] ^= x[i + 16];
    for (i = 0;i < 16;++i) y[i ^ 1] = x[i + 16];
    for (i = 0;i < 16;++i) x[i + 16] = y[i];
  }
}

__kernel int Init(__global uint *hashbitlen, __global uint *pos, __global uint *x)
{
  int i;
  
  if (*hashbitlen < 8) return 2;
  if (*hashbitlen > 512) return 2;
  if (*hashbitlen != 8 * (*hashbitlen / 8)) return 2;

  for (i = 0;i < 32;++i) x[i] = 0;

  x[0] = *hashbitlen / 8;
  x[1] = CUBEHASH_BLOCKBYTES;
  x[2] = CUBEHASH_ROUNDS;

  for (i = 0;i < 10;++i) transform(x);

  *pos = 0;

  return 0;
}

__kernel int Update(__global uint *pos, __global uint *x, __global uchar *_data,  __global uint *_databitlen)
{
  __global uchar *data = _data;
  uint databitlen = *_databitlen;

  while (databitlen >= 8) {
    uint u = *data;
    u <<= 8 * ((*pos / 8) % 4);
    x[*pos / 32] ^= u;
    data += 1;
    databitlen -= 8;
    *pos += 8;
    if (*pos == 8 * CUBEHASH_BLOCKBYTES) {
      transform(x);
      *pos = 0;
    }
  }

  if (databitlen > 0) {
    uint u = *data;
    u <<= 8 * ((*pos / 8) % 4);
    x[*pos / 32] ^= u;
    *pos += databitlen;
  }
  
  return 0;
}

__kernel int Final(__global uint *hashbitlen, __global uint *pos, __global uint *x, __global uchar *hashval)
{
  int i;
  uint u;

  u = (128 >> (*pos % 8));
  u <<= 8 * ((*pos / 8) % 4);
  x[*pos / 32] ^= u;
  transform(x);
  x[31] ^= 1;
  for (i = 0;i < 10;++i) transform(x);
  for (i = 0;i < *hashbitlen / 8;++i) hashval[i] = x[i / 4] >> (8 * (i % 4));
  
  return 0;
}

__kernel int Hash(__global uint *hashbitlen, __global uint *pos, __global uint *x, __global const uchar *data, __global uint *databitlen, __global uchar *hashval)
{
  Init(hashbitlen, pos, x);
  Update(pos, x, data, databitlen);
  Final(hashbitlen, pos, x, hashval);
  
  return 0;
}
