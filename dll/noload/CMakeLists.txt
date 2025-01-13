project(no_load_dll)

file(GLOB HEADER_FILES *.h)
file(GLOB SOURCE_FILES *.c *.cpp)

add_library(${PROJECT_NAME} SHARED ${HEADER_FILES} ${SOURCE_FILES})

EmbedVersionInformationBuildVariantSo(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/../.. " - " False)
