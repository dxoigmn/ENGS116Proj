#define CUBEHASH_ROUNDS 8
#define CUBEHASH_BLOCKBYTES 1

unsigned int ROTATE(unsigned int a, int b)
{
  return (((a) << (b)) | ((a) >> (32 - b)));
}

static void transform(unsigned int *x)
{
  int i;
  int r;
  unsigned int y[16];

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

__kernel int Hash(__global unsigned int *_hashbitlen, __global const unsigned char *data, __global unsigned int *_databitlen, __global unsigned char *hashval)
{
  int gid = get_global_id(0);
  unsigned int pos = 0;
  unsigned int x[32];
  int i;
  int j;
  int r;
  unsigned int u;
  unsigned int y[16];
  unsigned int databitlen = *_databitlen;
  unsigned int hashbitlen = *_hashbitlen;

  /*
  if (Init(hashbitlen, &pos, x) != 0) return 2;
  */

  if (hashbitlen < 8) return 2;
  if (hashbitlen > 512) return 2;
  if (hashbitlen != 8 * (hashbitlen / 8)) return 2;

  for (i = 0;i < 32;++i) x[i] = 0;
  x[0] = hashbitlen / 8;
  x[1] = CUBEHASH_BLOCKBYTES;
  x[2] = CUBEHASH_ROUNDS;

  for (i = 0;i < 10;++i) transform(x);

  /*
  Update(&pos, x, data, databitlen);
  */

  while (databitlen >= 8) {
    unsigned int u = *data;
    u <<= 8 * ((pos / 8) % 4);
    x[pos / 32] ^= u;
    data += 1;
    databitlen -= 8;
    pos += 8;
    if (pos == 8 * CUBEHASH_BLOCKBYTES) {
      transform(x);
      pos = 0;
    }
  }
  if (databitlen > 0) {
    unsigned int u = *data;
    u <<= 8 * ((pos / 8) % 4);
    x[pos / 32] ^= u;
    pos += databitlen;
  }

  /*
  return Final(hashbitlen, pos, x, hashval);
  */

  u = (128 >> (pos % 8));
  u <<= 8 * ((pos / 8) % 4);
  x[pos / 32] ^= u;
  transform(x);
  x[31] ^= 1;
  for (i = 0;i < 10;++i) transform(x);
  for (i = 0;i < hashbitlen / 8;++i) hashval[i] = x[i / 4] >> (8 * (i % 4));

  return 0;
}
