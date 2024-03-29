message(STATUS "CMAKE_VERSION='${CMAKE_VERSION}'")
message(STATUS "CMAKE_GENERATOR='${CMAKE_GENERATOR}'")

cmake_minimum_required(VERSION 3.11.0)

project (version_git_example1 C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(UNIX)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --std=c++17") 
else()
  set(CMAKE_C_FLAGS_DEBUG "/MD /MP /Zi /Ob0 /Od /RTC1")
  set(CMAKE_C_FLAGS_MINSIZEREL "/MD /MP /O1 /Ob1 /DNDEBUG")
  set(CMAKE_C_FLAGS_RELEASE "/MD /MP /O2 /Ob2 /DNDEBUG")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /MP /Zi /O2 /Ob1 /DNDEBUG")
  set(CMAKE_CXX_FLAGS_DEBUG "/MD /MP /W3 /Zi /Ob0 /Od /RTC1")
  set(CMAKE_CXX_FLAGS_MINSIZEREL "/MD /MP /W3 /O1 /Ob1 /DNDEBUG")
  set(CMAKE_CXX_FLAGS_RELEASE "/MD /MP /W3 /O2 /Ob2 /DNDEBUG")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /MP /W3 /Zi /O2 /Ob1 /DNDEBUG")
endif()

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake")

include(EmbedVersionInformation)
include(GeneratorResourceCode)

file(GLOB ${PROJECT_NAME}_INC ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
file(GLOB ${PROJECT_NAME}_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.c)

add_executable(${PROJECT_NAME} ${${PROJECT_NAME}_INC} ${${PROJECT_NAME}_SRC})

EmbedVersionInformation(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR})

GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "C" ${CMAKE_CURRENT_SOURCE_DIR}/resources/TEXT_RESOURCE.TXT)
GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "CPP" ${CMAKE_CURRENT_SOURCE_DIR}/resources/TEXT_RESOURCE2.TXT)

list(APPEND RES ${CMAKE_CURRENT_SOURCE_DIR}/resources/TEXT_RESOURCE3.TXT)
list(APPEND RES ${CMAKE_CURRENT_SOURCE_DIR}/resources/TEXT_RESOURCE4.TXT)

GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "C" ${RES})

add_subdirectory(second)

GenerateResourceFinalize()
