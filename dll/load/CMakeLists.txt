project(load_dll)

file(GLOB HEADER_FILES *.h)
file(GLOB SOURCE_FILES *.c *.cpp)

add_library(${PROJECT_NAME} SHARED ${HEADER_FILES} ${SOURCE_FILES})

EmbedVersionInformationBuildVariantSo(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/../.. " - " True)
GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "C" ${CMAKE_CURRENT_SOURCE_DIR}/../../resources/TEXT_RESOURCE.TXT)
GenerateResource(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/gen "CPP" ${CMAKE_CURRENT_SOURCE_DIR}/../../resources/TEXT_RESOURCE2.TXT)
