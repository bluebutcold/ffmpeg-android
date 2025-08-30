/*
 * OpenCL Stub Library for FFmpeg Android Build
 * 
 * This stub provides all OpenCL functions that FFmpeg uses,
 * returning appropriate error codes to indicate OpenCL is unavailable.
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

// OpenCL types
typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef size_t size_t;
typedef void* cl_platform_id;
typedef void* cl_device_id;
typedef void* cl_context;
typedef void* cl_command_queue;
typedef void* cl_mem;
typedef void* cl_program;
typedef void* cl_kernel;
typedef void* cl_event;

// OpenCL constants and error codes
#define CL_SUCCESS                          0
#define CL_DEVICE_NOT_FOUND                -1
#define CL_DEVICE_NOT_AVAILABLE            -2
#define CL_COMPILER_NOT_AVAILABLE          -3
#define CL_MEM_OBJECT_ALLOCATION_FAILURE   -4
#define CL_OUT_OF_RESOURCES                -5
#define CL_OUT_OF_HOST_MEMORY              -6
#define CL_PROFILING_INFO_NOT_AVAILABLE    -7
#define CL_MEM_COPY_OVERLAP                -8
#define CL_IMAGE_FORMAT_MISMATCH           -9
#define CL_IMAGE_FORMAT_NOT_SUPPORTED      -10
#define CL_BUILD_PROGRAM_FAILURE           -11
#define CL_MAP_FAILURE                     -12
#define CL_INVALID_VALUE                   -30
#define CL_INVALID_DEVICE_TYPE             -31
#define CL_INVALID_PLATFORM                -32
#define CL_INVALID_DEVICE                  -33
#define CL_INVALID_CONTEXT                 -34
#define CL_INVALID_QUEUE_PROPERTIES        -35
#define CL_INVALID_COMMAND_QUEUE           -36
#define CL_INVALID_HOST_PTR                -37
#define CL_INVALID_MEM_OBJECT              -38
#define CL_INVALID_IMAGE_FORMAT_DESCRIPTOR -39
#define CL_INVALID_IMAGE_SIZE              -40
#define CL_INVALID_SAMPLER                 -41
#define CL_INVALID_BINARY                  -42
#define CL_INVALID_BUILD_OPTIONS           -43
#define CL_INVALID_PROGRAM                 -44
#define CL_INVALID_PROGRAM_EXECUTABLE      -45
#define CL_INVALID_KERNEL_NAME             -46
#define CL_INVALID_KERNEL_DEFINITION       -47
#define CL_INVALID_KERNEL                  -48
#define CL_INVALID_ARG_INDEX               -49
#define CL_INVALID_ARG_VALUE               -50
#define CL_INVALID_ARG_SIZE                -51
#define CL_INVALID_KERNEL_ARGS             -52
#define CL_INVALID_WORK_DIMENSION          -53
#define CL_INVALID_WORK_GROUP_SIZE         -54
#define CL_INVALID_WORK_ITEM_SIZE          -55
#define CL_INVALID_GLOBAL_OFFSET           -56
#define CL_INVALID_EVENT_WAIT_LIST         -57
#define CL_INVALID_EVENT                   -58
#define CL_INVALID_OPERATION               -59
#define CL_INVALID_GL_OBJECT               -60
#define CL_INVALID_BUFFER_SIZE             -61
#define CL_INVALID_MIP_LEVEL               -62
#define CL_INVALID_GLOBAL_WORK_SIZE        -63
#define CL_PLATFORM_NOT_FOUND_KHR           -1001

// Memory object info
#define CL_MEM_TYPE                        0x1100
#define CL_MEM_OBJECT_IMAGE2D              0x10F1

// Image info  
#define CL_IMAGE_WIDTH                     0x1116
#define CL_IMAGE_HEIGHT                    0x1117

// Program build info
#define CL_PROGRAM_BUILD_LOG               0x1183

// Profiling info
#define CL_PROFILING_COMMAND_START         0x1282
#define CL_PROFILING_COMMAND_END           0x1283

// Boolean
#define CL_TRUE                            1
#define CL_FALSE                           0

// Stub function implementations
// All functions return appropriate error codes indicating OpenCL is not available

cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms) {
    if (num_platforms) *num_platforms = 0;
    return CL_DEVICE_NOT_FOUND;
}

cl_int clGetDeviceIDs(cl_platform_id platform, cl_uint device_type, cl_uint num_entries, 
                      cl_device_id *devices, cl_uint *num_devices) {
    if (num_devices) *num_devices = 0;
    return CL_DEVICE_NOT_FOUND;
}

// Dummy handle values to avoid NULL pointer crashes
#define DUMMY_CONTEXT       ((cl_context)0x1)
#define DUMMY_QUEUE         ((cl_command_queue)0x2)
#define DUMMY_PROGRAM       ((cl_program)0x3)
#define DUMMY_KERNEL        ((cl_kernel)0x4)
#define DUMMY_BUFFER        ((cl_mem)0x5)

cl_context clCreateContext(const void *properties, cl_uint num_devices, 
                          const cl_device_id *devices, void *pfn_notify, 
                          void *user_data, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_AVAILABLE;
    return NULL; // Return NULL here to fail early in FFmpeg initialization
}

cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device, 
                                     cl_uint properties, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL; // Return NULL here to fail early
}

cl_program clCreateProgramWithSource(cl_context context, cl_uint count, 
                                    const char **strings, const size_t *lengths, 
                                    cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL; // Return NULL to fail program creation
}

cl_int clBuildProgram(cl_program program, cl_uint num_devices, 
                     const cl_device_id *device_list, const char *options, 
                     void *pfn_notify, void *user_data) {
    return CL_BUILD_PROGRAM_FAILURE; // Clear build failure
}

cl_int clGetProgramBuildInfo(cl_program program, cl_device_id device, 
                           cl_uint param_name, size_t param_value_size, 
                           void *param_value, size_t *param_value_size_ret) {
    // Provide a fake error message for build log requests
    if (param_name == CL_PROGRAM_BUILD_LOG) {
        const char *msg = "OpenCL not available on this device";
        size_t msg_len = strlen(msg) + 1;
        
        if (param_value_size_ret) *param_value_size_ret = msg_len;
        
        if (param_value && param_value_size >= msg_len) {
            strcpy((char*)param_value, msg);
        }
        return CL_SUCCESS;
    }
    
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_PROGRAM;
}

cl_int clReleaseProgram(cl_program program) {
    return CL_SUCCESS; // Safe no-op release
}

cl_kernel clCreateKernel(cl_program program, const char *kernel_name, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_PROGRAM;
    return NULL; // Return NULL to fail kernel creation
}

cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size, const void *arg_value) {
    return CL_INVALID_KERNEL;
}

cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel, 
                             cl_uint work_dim, const size_t *global_work_offset, 
                             const size_t *global_work_size, const size_t *local_work_size, 
                             cl_uint num_events_in_wait_list, const cl_event *event_wait_list, 
                             cl_event *event) {
    return CL_INVALID_KERNEL;
}

cl_int clFinish(cl_command_queue command_queue) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clReleaseKernel(cl_kernel kernel) {
    return CL_SUCCESS; // Safe no-op release
}

cl_int clReleaseMemObject(cl_mem memobj) {
    return CL_SUCCESS; // Safe no-op release
}

cl_int clReleaseCommandQueue(cl_command_queue command_queue) {
    return CL_SUCCESS; // Safe no-op release
}

cl_int clGetMemObjectInfo(cl_mem memobj, cl_uint param_name, size_t param_value_size, 
                         void *param_value, size_t *param_value_size_ret) {
    return CL_INVALID_MEM_OBJECT;
}

cl_int clGetImageInfo(cl_mem image, cl_uint param_name, size_t param_value_size, 
                     void *param_value, size_t *param_value_size_ret) {
    return CL_INVALID_MEM_OBJECT;
}

cl_mem clCreateBuffer(cl_context context, cl_uint flags, size_t size, 
                     void *host_ptr, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL; // Return NULL to fail buffer creation
}

cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer, cl_uint blocking_write, 
                           size_t offset, size_t size, const void *ptr, 
                           cl_uint num_events_in_wait_list, const cl_event *event_wait_list, 
                           cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clGetEventProfilingInfo(cl_event event, cl_uint param_name, size_t param_value_size, 
                              void *param_value, size_t *param_value_size_ret) {
    return CL_PROFILING_INFO_NOT_AVAILABLE;
}

// Additional functions needed by hwcontext_opencl.c and OpenCL filters
cl_int clRetainCommandQueue(cl_command_queue command_queue) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clGetDeviceInfo(cl_device_id device, cl_uint param_name, size_t param_value_size,
                      void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_DEVICE;
}

cl_int clGetSupportedImageFormats(cl_context context, cl_uint flags, cl_uint image_type,
                                 cl_uint num_entries, void *image_formats, cl_uint *num_image_formats) {
    if (num_image_formats) *num_image_formats = 0;
    return CL_INVALID_CONTEXT;
}

cl_int clEnqueueWriteImage(cl_command_queue command_queue, cl_mem image, cl_uint blocking_write,
                          const size_t *origin, const size_t *region, size_t input_row_pitch,
                          size_t input_slice_pitch, const void *ptr, cl_uint num_events_in_wait_list,
                          const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clWaitForEvents(cl_uint num_events, const cl_event *event_list) {
    return CL_INVALID_EVENT;
}

cl_int clReleaseEvent(cl_event event) {
    return CL_SUCCESS; // Safe no-op release
}

cl_int clEnqueueReadImage(cl_command_queue command_queue, cl_mem image, cl_uint blocking_read,
                         const size_t *origin, const size_t *region, size_t row_pitch,
                         size_t slice_pitch, void *ptr, cl_uint num_events_in_wait_list,
                         const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

void* clEnqueueMapImage(cl_command_queue command_queue, cl_mem image, cl_uint blocking_map,
                       cl_uint map_flags, const size_t *origin, const size_t *region,
                       size_t *image_row_pitch, size_t *image_slice_pitch,
                       cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                       cl_event *event, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_COMMAND_QUEUE;
    return NULL;
}

cl_int clEnqueueUnmapMemObject(cl_command_queue command_queue, cl_mem memobj, void *mapped_ptr,
                              cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                              cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clGetPlatformInfo(cl_platform_id platform, cl_uint param_name, size_t param_value_size,
                        void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_PLATFORM;
}

cl_int clReleaseContext(cl_context context) {
    return CL_SUCCESS; // Safe no-op release
}

cl_mem clCreateImage(cl_context context, cl_uint flags, const void *image_format,
                    const void *image_desc, void *host_ptr, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_int clEnqueueFillBuffer(cl_command_queue command_queue, cl_mem buffer, const void *pattern,
                          size_t pattern_size, size_t offset, size_t size,
                          cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                          cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clFlush(cl_command_queue command_queue) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer, cl_uint blocking_read,
                          size_t offset, size_t size, void *ptr, cl_uint num_events_in_wait_list,
                          const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueCopyImage(cl_command_queue command_queue, cl_mem src_image, cl_mem dst_image,
                         const size_t *src_origin, const size_t *dst_origin, const size_t *region,
                         cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                         cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

// Additional standard OpenCL functions that may be needed
cl_int clRetainProgram(cl_program program) {
    return CL_SUCCESS;
}

cl_int clRetainKernel(cl_kernel kernel) {
    return CL_SUCCESS;
}

cl_int clRetainEvent(cl_event event) {
    return CL_SUCCESS;
}

cl_int clRetainContext(cl_context context) {
    return CL_SUCCESS;
}

cl_int clRetainMemObject(cl_mem memobj) {
    return CL_SUCCESS;
}

cl_mem clCreateSubBuffer(cl_context context, cl_mem buffer, cl_uint flags,
                        cl_uint buffer_create_type, const void *buffer_create_info,
                        cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_int clEnqueueCopyBuffer(cl_command_queue command_queue, cl_mem src_buffer, cl_mem dst_buffer,
                          size_t src_offset, size_t dst_offset, size_t size,
                          cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                          cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueCopyBufferRect(cl_command_queue command_queue, cl_mem src_buffer, cl_mem dst_buffer,
                              const size_t *src_origin, const size_t *dst_origin, const size_t *region,
                              size_t src_row_pitch, size_t src_slice_pitch, size_t dst_row_pitch,
                              size_t dst_slice_pitch, cl_uint num_events_in_wait_list,
                              const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueCopyBufferToImage(cl_command_queue command_queue, cl_mem src_buffer, cl_mem dst_image,
                                 size_t src_offset, const size_t *dst_origin, const size_t *region,
                                 cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                                 cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueCopyImageToBuffer(cl_command_queue command_queue, cl_mem src_image, cl_mem dst_buffer,
                                 const size_t *src_origin, size_t dst_offset, const size_t *region,
                                 cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                                 cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

// Additional utility functions that FFmpeg might use
cl_int clGetContextInfo(cl_context context, cl_uint param_name, size_t param_value_size,
                       void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_CONTEXT;
}

cl_int clGetCommandQueueInfo(cl_command_queue command_queue, cl_uint param_name,
                           size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clGetEventInfo(cl_event event, cl_uint param_name, size_t param_value_size,
                     void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_EVENT;
}

cl_int clGetKernelInfo(cl_kernel kernel, cl_uint param_name, size_t param_value_size,
                      void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_KERNEL;
}

cl_int clGetKernelWorkGroupInfo(cl_kernel kernel, cl_device_id device, cl_uint param_name,
                               size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_KERNEL;
}

// Image creation functions
cl_mem clCreateImage2D(cl_context context, cl_uint flags, const void *image_format,
                      size_t image_width, size_t image_height, size_t image_row_pitch,
                      void *host_ptr, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateImage3D(cl_context context, cl_uint flags, const void *image_format,
                      size_t image_width, size_t image_height, size_t image_depth,
                      size_t image_row_pitch, size_t image_slice_pitch, void *host_ptr,
                      cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

// Context creation
cl_context clCreateContextFromType(const void *properties, cl_uint device_type,
                                  void *pfn_notify, void *user_data, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return NULL;
}

// Sampler functions
cl_mem clCreateSampler(cl_context context, cl_uint normalized_coords, cl_uint addressing_mode,
                      cl_uint filter_mode, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_int clRetainSampler(cl_mem sampler) {
    return CL_SUCCESS;
}

cl_int clReleaseSampler(cl_mem sampler) {
    return CL_SUCCESS;
}

cl_int clGetSamplerInfo(cl_mem sampler, cl_uint param_name, size_t param_value_size,
                       void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_SAMPLER;
}

// User events
cl_event clCreateUserEvent(cl_context context, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_int clSetUserEventStatus(cl_event event, cl_int execution_status) {
    return CL_INVALID_EVENT;
}

// Event callbacks
cl_int clSetEventCallback(cl_event event, cl_int command_exec_callback_type,
                         void *pfn_notify, void *user_data) {
    return CL_INVALID_EVENT;
}

// Queue operations
cl_int clEnqueueMarker(cl_command_queue command_queue, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueBarrier(cl_command_queue command_queue) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueMarkerWithWaitList(cl_command_queue command_queue, cl_uint num_events_in_wait_list,
                                  const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueBarrierWithWaitList(cl_command_queue command_queue, cl_uint num_events_in_wait_list,
                                   const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueTask(cl_command_queue command_queue, cl_kernel kernel,
                    cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                    cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueNativeKernel(cl_command_queue command_queue, void (*user_func)(void *),
                            void *args, size_t cb_args, cl_uint num_mem_objects,
                            const cl_mem *mem_list, const void **args_mem_loc,
                            cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                            cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

// Kernel info functions
cl_int clCreateKernelsInProgram(cl_program program, cl_uint num_kernels,
                               cl_kernel *kernels, cl_uint *num_kernels_ret) {
    if (num_kernels_ret) *num_kernels_ret = 0;
    return CL_INVALID_PROGRAM;
}

cl_int clGetKernelArgInfo(cl_kernel kernel, cl_uint arg_indx, cl_uint param_name,
                         size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_KERNEL;
}

// Compiler functions
cl_int clUnloadCompiler(void) {
    return CL_SUCCESS;
}

cl_int clUnloadPlatformCompiler(cl_platform_id platform) {
    return CL_SUCCESS;
}

// OpenCL 2.0 functions
cl_command_queue clCreateCommandQueueWithProperties(cl_context context, cl_device_id device,
                                                   const void *properties, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateSamplerWithProperties(cl_context context, const void *sampler_properties,
                                    cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

// SVM (Shared Virtual Memory) functions - OpenCL 2.0
void* clSVMAlloc(cl_context context, cl_uint flags, size_t size, cl_uint alignment) {
    return NULL;
}

void clSVMFree(cl_context context, void *svm_pointer) {
    // No-op
}

cl_int clEnqueueSVMFree(cl_command_queue command_queue, cl_uint num_svm_pointers,
                       void *svm_pointers[], void (*pfn_free_func)(cl_command_queue, cl_uint, void *[], void *),
                       void *user_data, cl_uint num_events_in_wait_list,
                       const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueSVMMemcpy(cl_command_queue command_queue, cl_uint blocking_copy,
                         void *dst_ptr, const void *src_ptr, size_t size,
                         cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                         cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueSVMMemFill(cl_command_queue command_queue, void *svm_ptr, const void *pattern,
                          size_t pattern_size, size_t size, cl_uint num_events_in_wait_list,
                          const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueSVMMap(cl_command_queue command_queue, cl_uint blocking_map, cl_uint flags,
                      void *svm_ptr, size_t size, cl_uint num_events_in_wait_list,
                      const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueSVMUnmap(cl_command_queue command_queue, void *svm_ptr,
                        cl_uint num_events_in_wait_list, const cl_event *event_wait_list,
                        cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clSetKernelArgSVMPointer(cl_kernel kernel, cl_uint arg_index, const void *arg_value) {
    return CL_INVALID_KERNEL;
}

cl_int clSetKernelExecInfo(cl_kernel kernel, cl_uint param_name, size_t param_value_size,
                          const void *param_value) {
    return CL_INVALID_KERNEL;
}

// Extension function address queries
void* clGetExtensionFunctionAddress(const char *function_name) {
    return NULL;
}

void* clGetExtensionFunctionAddressForPlatform(cl_platform_id platform, const char *function_name) {
    return NULL;
}

// ICD functions
cl_int clIcdGetPlatformIDsKHR(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms) {
    if (num_platforms) *num_platforms = 0;
    return CL_PLATFORM_NOT_FOUND_KHR;
}

// OpenGL interop functions (commonly used)
cl_mem clCreateFromGLBuffer(cl_context context, cl_uint flags, cl_uint bufobj, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateFromGLTexture(cl_context context, cl_uint flags, cl_uint target,
                            cl_int miplevel, cl_uint texture, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateFromGLTexture2D(cl_context context, cl_uint flags, cl_uint target,
                              cl_int miplevel, cl_uint texture, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateFromGLTexture3D(cl_context context, cl_uint flags, cl_uint target,
                              cl_int miplevel, cl_uint texture, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_mem clCreateFromGLRenderbuffer(cl_context context, cl_uint flags, cl_uint renderbuffer,
                                 cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_INVALID_CONTEXT;
    return NULL;
}

cl_int clGetGLObjectInfo(cl_mem memobj, cl_uint *gl_object_type, cl_uint *gl_object_name) {
    return CL_INVALID_MEM_OBJECT;
}

cl_int clGetGLTextureInfo(cl_mem memobj, cl_uint param_name, size_t param_value_size,
                         void *param_value, size_t *param_value_size_ret) {
    if (param_value_size_ret) *param_value_size_ret = 0;
    return CL_INVALID_MEM_OBJECT;
}

cl_int clEnqueueAcquireGLObjects(cl_command_queue command_queue, cl_uint num_objects,
                                const cl_mem *mem_objects, cl_uint num_events_in_wait_list,
                                const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}

cl_int clEnqueueReleaseGLObjects(cl_command_queue command_queue, cl_uint num_objects,
                                const cl_mem *mem_objects, cl_uint num_events_in_wait_list,
                                const cl_event *event_wait_list, cl_event *event) {
    return CL_INVALID_COMMAND_QUEUE;
}
