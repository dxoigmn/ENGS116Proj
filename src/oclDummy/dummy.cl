__kernel int Hash(__global int *mem)
{
  *mem = 0xbaadf00d;
  return 0;
}