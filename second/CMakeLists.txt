project (version_git_example2)

file(GLOB ${PROJECT_NAME}_INC ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
file(GLOB ${PROJECT_NAME}_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.c ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

add_executable(${PROJECT_NAME} ${${PROJECT_NAME}_INC} ${${PROJECT_NAME}_SRC})

EmbedVersionInformation(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/..)

GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "C" ${CMAKE_CURRENT_SOURCE_DIR}/../resources/TEXT_RESOURCE.TXT)
GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "CPP" ${CMAKE_CURRENT_SOURCE_DIR}/../resources/TEXT_RESOURCE2.TXT)

list(APPEND RES ${CMAKE_CURRENT_SOURCE_DIR}/../resources/TEXT_RESOURCE3.TXT)
list(APPEND RES ${CMAKE_CURRENT_SOURCE_DIR}/../resources/TEXT_RESOURCE4.TXT)

GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "CPP" ${RES})
