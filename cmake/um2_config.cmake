## Update git submodules #########################
##################################################
include(cmake/update-git-submodules.cmake)

## System ########################################
##################################################
# No Windows support
if (WIN32)
  message(FATAL_ERROR "Windows is not supported")
endif()

## Compiler ######################################
##################################################
# Check for gcc and clang
if (NOT (CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR
         CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
  message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()

## Standard ######################################
##################################################
set(UM2_CXX_STANDARD "20" CACHE STRING "C++ standard")
set_target_properties(um2 PROPERTIES CXX_STANDARD ${UM2_CXX_STANDARD})
set_target_properties(um2 PROPERTIES CXX_STANDARD_REQUIRED ON)

## OpenMP ########################################
##################################################
if (UM2_ENABLE_OPENMP)
  find_package(OpenMP REQUIRED)
endif()

## CUDA ##########################################
##################################################
if (UM2_ENABLE_CUDA)
  include(CheckLanguage)
  check_language(CUDA)
  set(UM2_CUDA_STANDARD "20" CACHE STRING "CUDA standard")
  set_target_properties(um2 PROPERTIES CUDA_STANDARD ${UM2_CUDA_STANDARD})
  set_target_properties(um2 PROPERTIES CUDA_STANDARD_REQUIRED ON)
  # nvcc will default to gcc and g++ if the host compiler is not set using CUDAHOSTCXX. 
  # To prevent unintentional version/compiler mismatches, we set the host compiler to the 
  # same compiler used to build the project.
  if (NOT DEFINED ENV{CUDAHOSTCXX})
    message(STATUS "Setting CMAKE_CUDA_HOST_COMPILER to ${CMAKE_CXX_COMPILER}." 
      " Consider setting the CUDAHOSTCXX environment variable if this is not desired.")
    set(CMAKE_CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
  endif()
  find_package(CUDA REQUIRED)
  enable_language(CUDA)
  set_target_properties(um2 PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
  set_target_properties(um2 PROPERTIES CUDA_ARCHITECTURES native)
  set_source_files_properties(${UM2_SOURCES} PROPERTIES LANGUAGE CUDA)    
  target_include_directories(um2 SYSTEM PUBLIC "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")    
endif()

## Thrust ########################################
##################################################
set(Thrust_DIR "${PROJECT_SOURCE_DIR}/tpls/thrust/thrust/cmake")
find_package(Thrust REQUIRED CONFIG)
# Host backend (OpenMP > Sequential)
if (UM2_ENABLE_OPENMP)
  set(UM2_THRUST_HOST "OMP" CACHE STRING "Thrust host backend")
else()
  set(UM2_THRUST_HOST "CPP" CACHE STRING "Thrust host backend")
endif()
set_property(CACHE UM2_THRUST_HOST PROPERTY STRINGS "OMP" "CPP")
# Device backend (CUDA > OpenMP > Sequential)
if (UM2_ENABLE_CUDA)
  set(UM2_THRUST_DEVICE "CUDA" CACHE STRING "Thrust device backend")
elseif (UM2_ENABLE_OPENMP)
  set(UM2_THRUST_DEVICE "OMP" CACHE STRING "Thrust device backend")
else()
  set(UM2_THRUST_DEVICE "CPP" CACHE STRING "Thrust device backend")
endif()
set_property(CACHE UM2_THRUST_DEVICE PROPERTY STRINGS "CUDA" "OMP" "CPP")
message(STATUS "Thrust host backend: ${UM2_THRUST_HOST}")
message(STATUS "Thrust device backend: ${UM2_THRUST_DEVICE}")
thrust_create_target(Thrust HOST ${UM2_THRUST_HOST} DEVICE ${UM2_THRUST_DEVICE})
# Treat the Thrust includes as system includes    
target_link_libraries(um2 PRIVATE Thrust)
target_include_directories(um2 SYSTEM PUBLIC      
  "${PROJECT_SOURCE_DIR}/tpls/thrust/thrust/cmake/../.."    
  "${PROJECT_SOURCE_DIR}/tpls/thrust/dependencies/libcudacxx/include"    
  "${PROJECT_SOURCE_DIR}/tpls/thrust/dependencies/cub")

## spdlog ########################################
##################################################
add_subdirectory("${PROJECT_SOURCE_DIR}/tpls/spdlog" SYSTEM)
if (UM2_LOG_LEVEL STREQUAL "trace")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_TRACE")
elseif (UM2_LOG_LEVEL STREQUAL "debug")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_DEBUG")
elseif (UM2_LOG_LEVEL STREQUAL "info")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_INFO")
elseif (UM2_LOG_LEVEL STREQUAL "warn")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_WARN")
elseif (UM2_LOG_LEVEL STREQUAL "err")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_ERROR")
elseif (UM2_LOG_LEVEL STREQUAL "critical")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_CRITICAL")
elseif (UM2_LOG_LEVEL STREQUAL "off")
  set(UM2_SPDLOG_LEVEL "SPDLOG_LEVEL_OFF")
else()
  message(FATAL_ERROR "Unknown log level: ${UM2_LOG_LEVEL}")
endif()
target_link_libraries(um2 PRIVATE spdlog::spdlog)

## config.hpp ####################################
##################################################
configure_file(
  "${PROJECT_SOURCE_DIR}/cmake/config.hpp.in"
  "${PROJECT_SOURCE_DIR}/include/um2/common/config.hpp")

## clang-format ##################################
##################################################
if (UM2_ENABLE_CLANG_FORMAT)
  include(cmake/clang-format.cmake)
endif()

## clang-tidy ####################################
##################################################
if (UM2_ENABLE_CLANG_TIDY)
  if (UM2_CLANG_TIDY_FIX)
    set_target_properties(um2 PROPERTIES
                          CXX_CLANG_TIDY
                          "clang-tidy;--fix")
  else()
    set_target_properties(um2 PROPERTIES
                          CXX_CLANG_TIDY
                          "clang-tidy")
  endif()
endif()

## cppcheck ######################################
##################################################
if (UM2_ENABLE_CPPCHECK)
  # Concatenate the cppcheck arguments into a single string
  string(CONCAT CPPCHECK_ARGS
    "cppcheck"
    ";--enable=warning,style,information,missingInclude"
    ";--std=c++20"
    ";--language=c++"
    ";--suppress=missingIncludeSystem"
    ";--inconclusive"
    ";--inline-suppr"
    ";--error-exitcode=10")
  set_target_properties(um2 PROPERTIES CXX_CPPCHECK "${CPPCHECK_ARGS}")
endif()

## flags #########################################
##################################################
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  include(cmake/clang-cxx-flags.cmake)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${UM2_CLANG_FLAGS}")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  include(cmake/gnu-cxx-flags.cmake)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${UM2_GNU_FLAGS}")
endif()
if (UM2_ENABLE_FASTMATH)
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -ffast-math")
  if (UM2_ENABLE_CUDA)
    set(CMAKE_CUDA_FLAGS_RELEASE "${CMAKE_CUDA_FLAGS_RELEASE} --use_fast_math")
  endif()
endif()
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")
set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address,undefined")
# If CUDA is enabled, pass the CXX flags via -Xcompiler
if (UM2_ENABLE_CUDA)
  set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler \"${CMAKE_CXX_FLAGS}\"")
  set(CMAKE_CUDA_FLAGS_RELEASE "${CMAKE_CUDA_FLAGS_RELEASE} -Xcompiler \"${CMAKE_CXX_FLAGS_RELEASE}\"")
  set(CMAKE_CUDA_FLAGS_DEBUG   "${CMAKE_CUDA_FLAGS_DEBUG} -Xcompiler \"${CMAKE_CXX_FLAGS_DEBUG}\"")
endif()

## Tests #########################################
##################################################
if (UM2_ENABLE_TESTS)
  include(CTest)
  add_subdirectory(tests)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
