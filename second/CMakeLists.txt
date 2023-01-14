project (version_git_example2)

file(GLOB ${PROJECT_NAME}_INC ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
file(GLOB ${PROJECT_NAME}_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

add_executable(${PROJECT_NAME} ${${PROJECT_NAME}_INC} ${${PROJECT_NAME}_SRC})

EnsureVersionInformation(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/..)
