#include <oclUtils.h>

int main(int argc, char **argv)
{
  cl_int ciErr;

  // Create Context
  cl_context cxGPUContext = clCreateContextFromType(0, CL_DEVICE_TYPE_CPU, 0, 0, &ciErr);
  oclCheckError(ciErr);

  // Get the list of GPU devices associated with context
  size_t szParmDataBytes;

  ciErr = clGetContextInfo(cxGPUContext, CL_CONTEXT_DEVICES, 0, 0, &szParmDataBytes);
  oclCheckError(ciErr);

  cl_device_id* cdDevices = (cl_device_id*)malloc(szParmDataBytes);

  ciErr = clGetContextInfo(cxGPUContext, CL_CONTEXT_DEVICES, szParmDataBytes, cdDevices, 0);
  oclCheckError(ciErr);

  // Create a command-queue
  cl_command_queue cqCommandQueue = clCreateCommandQueue(cxGPUContext, cdDevices[0], 0, &ciErr);
  oclCheckError(ciErr);

  // Read the OpenCL kernel in from source file
  size_t szProgramLength;

  char *cPathAndName = shrFindFilePath("cube_hash.cl", argv[0]);
  shrCheckError(cPathAndName != 0, shrTRUE);

  char *cSourceCL = oclLoadProgSource(cPathAndName, "", &szProgramLength);
  shrCheckError(cSourceCL != 0, shrTRUE);

  cl_program cpProgram = clCreateProgramWithSource(cxGPUContext, 1, (const char **)&cSourceCL, &szProgramLength, &ciErr);
  oclCheckError(ciErr);

  // Build the program
  ciErr = clBuildProgram(cpProgram, 0, 0, 0, 0, 0);
  
  if (ciErr == CL_BUILD_PROGRAM_FAILURE) {
    cl_build_status build_status;
    ciErr = clGetProgramBuildInfo(cpProgram, cdDevices[0], CL_PROGRAM_BUILD_STATUS, sizeof(cl_build_status), &build_status, NULL);
    oclCheckError(ciErr);

    size_t build_log_size;
    ciErr = clGetProgramBuildInfo(cpProgram, cdDevices[0], CL_PROGRAM_BUILD_LOG, 0, NULL, &build_log_size);
    oclCheckError(ciErr);

    char *build_log = (char *)malloc(build_log_size + 1);
    clGetProgramBuildInfo(cpProgram, cdDevices[0], CL_PROGRAM_BUILD_LOG, build_log_size, build_log, NULL);
    oclCheckError(ciErr);

    build_log[build_log_size] = '\0';

    fprintf(stderr, "BUILD LOG:\n");
    fprintf(stderr, "%s\n", build_log);

    free(build_log);
  }

  oclCheckError(ciErr);

/*
  __kernel int Hash(__global int hashbitlen, 
                    __global const unsigned char *data,
                    __global unsigned int databitlen,
                    __global unsigned char *hashval)
*/

  // Create the "prepare" kernel
  cl_kernel ckKernel = clCreateKernel(cpProgram, "Hash", &ciErr);
  oclCheckError(ciErr);

  // Allocate the OpenCL buffer memory objects for source and result on the device GMEM and set arguments for kernel
  unsigned int hashbitlen = 64;
  unsigned char data[] = "abc";
  unsigned int databitlen = strlen((char *)data) * 8;
  unsigned char hashval[hashbitlen / 8];

  cl_mem cmHashBitLen = clCreateBuffer(cxGPUContext, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sizeof(databitlen), &hashbitlen, &ciErr);
  oclCheckError(ciErr);
  ciErr = clSetKernelArg(ckKernel, 0, sizeof(cl_mem), (void*)&cmHashBitLen);
  oclCheckError(ciErr);

  cl_mem cmData = clCreateBuffer(cxGPUContext, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, databitlen / 8, &data, &ciErr);
  oclCheckError(ciErr);
  ciErr = clSetKernelArg(ckKernel, 1, sizeof(cl_mem), (void*)&cmData);
  oclCheckError(ciErr);

  cl_mem cmDataBitLen = clCreateBuffer(cxGPUContext, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(databitlen), &databitlen, &ciErr);
  oclCheckError(ciErr);
  ciErr = clSetKernelArg(ckKernel, 2, sizeof(cl_mem), (void*)&cmDataBitLen);
  oclCheckError(ciErr);

  cl_mem cmHashVal = clCreateBuffer(cxGPUContext, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR, hashbitlen / 8, hashval, &ciErr);
  oclCheckError(ciErr);
  ciErr = clSetKernelArg(ckKernel, 3, sizeof(cl_mem), (void*)&cmHashVal);
  oclCheckError(ciErr);

  // Launch kernel
  size_t szGlobalWorkSize = 4;
  ciErr = clEnqueueNDRangeKernel(cqCommandQueue, ckKernel, 1, 0, &szGlobalWorkSize, 0, 0, 0, 0);
  oclCheckError(ciErr);

  // Synchronous/blocking read of results, and check accumulated errors
  ciErr = clEnqueueReadBuffer(cqCommandQueue, cmHashVal, CL_TRUE, 0, hashbitlen / 8, hashval, 0, 0, 0);
  oclCheckError(ciErr);

  for (unsigned int i = 0; i < databitlen / 8; i++) {
    printf("%02x", hashval[i]);
  }
  printf("\n");

  if (cdDevices)      free(cdDevices);
  if (cPathAndName)   free(cPathAndName);
  if (cSourceCL)      free(cSourceCL);
  if (ckKernel)       clReleaseKernel(ckKernel);
  if (cpProgram)      clReleaseProgram(cpProgram);
  if (cqCommandQueue) clReleaseCommandQueue(cqCommandQueue);
  if (cxGPUContext)   clReleaseContext(cxGPUContext);
  if (cmHashBitLen)   clReleaseMemObject(cmHashBitLen);
  if (cmData)         clReleaseMemObject(cmData);
  if (cmDataBitLen)   clReleaseMemObject(cmDataBitLen);
  if (cmHashVal)      clReleaseMemObject(cmHashVal);

  return 0;
}
