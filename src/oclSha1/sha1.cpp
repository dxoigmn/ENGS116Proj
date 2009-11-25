#include <oclUtils.h>

void sha1(uint *W, uint *H, const uint *work_items);
void prepare(char *msg, const int *len, uint *W);
void hexdigest(const uint *H, char *digest);

int main(int argc, char **argv)
{
  cl_int ciErr;

  // Create Context
  cl_context cxGPUContext = clCreateContextFromType(0, CL_DEVICE_TYPE_GPU, NULL, NULL, &ciErr);
  oclCheckError(ciErr);

  // Get the list of GPU devices associated with context
  size_t szParmDataBytes;

  ciErr = clGetContextInfo(cxGPUContext, CL_CONTEXT_DEVICES, 0, NULL, &szParmDataBytes);
  oclCheckError(ciErr);

  cl_device_id* cdDevices = (cl_device_id*)malloc(szParmDataBytes);

  ciErr = clGetContextInfo(cxGPUContext, CL_CONTEXT_DEVICES, szParmDataBytes, cdDevices, NULL);
  oclCheckError(ciErr);

  // Create a command-queue
  cl_command_queue cqCommandQueue = clCreateCommandQueue(cxGPUContext, cdDevices[0], 0, &ciErr);
  oclCheckError(ciErr);

  // Read the OpenCL kernel in from source file
  size_t szProgramLength;

  char *cPathAndName = shrFindFilePath("sha1.cl", argv[0]);
  shrCheckError(cPathAndName != NULL, shrTRUE);

  char *cSourceCL = oclLoadProgSource(cPathAndName, "", &szProgramLength);
  shrCheckError(cSourceCL != NULL, shrTRUE);

  cl_program cpProgram = clCreateProgramWithSource(cxGPUContext, 1, (const char **)&cSourceCL, &szProgramLength, &ciErr);
  oclCheckError(ciErr);

  // Build the program
  ciErr = clBuildProgram(cpProgram, 0, NULL, NULL, NULL, NULL);
  oclCheckError(ciErr);

  // Create the "prepare" kernel
  cl_kernel ckKernelPrepare = clCreateKernel(cpProgram, "prepare", &ciErr);
  oclCheckError(ciErr);

  // Allocate the OpenCL buffer memory objects for source and result on the device GMEM
  cl_mem cmDevSrcA = clCreateBuffer(cxGPUContext, CL_MEM_READ_ONLY, SIZE, NULL, &ciErr);
  oclCheckError(ciErr);
  
  cl_mem cmDevSrcB = clCreateBuffer(cxGPUContext, CL_MEM_READ_ONLY, SIZE, NULL, &ciErr);
  oclCheckError(ciErr);
  
  cl_mem cmDevDst = clCreateBuffer(cxGPUContext, CL_MEM_WRITE_ONLY, SIZE, NULL, &ciErr);
  oclCheckError(ciErr);
  
  // Set the Argument values
  ciErr = clSetKernelArg(ckKernel, 0, sizeof(cl_mem), (void*)&cmDevSrcA);
  oclCheckError(ciErr);
  
  ciErr = clSetKernelArg(ckKernel, 1, sizeof(cl_mem), (void*)&cmDevSrcB);
  oclCheckError(ciErr);
  
  ciErr = clSetKernelArg(ckKernel, 2, sizeof(cl_mem), (void*)&cmDevDst);
  oclCheckError(ciErr);
  
  ciErr = clSetKernelArg(ckKernel, 3, sizeof(cl_int), (void*)&iNumElements);
  oclCheckError(ciErr);
}
