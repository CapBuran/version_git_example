function(FileCopyIsChanged FullPathSrc FullPathDst)
  set(IsChanged 0)

  if(NOT EXISTS ${FullPathDst})
    set(IsChanged 1)
  else()
    file(READ ${FullPathSrc} TMP_SRC)
    file(READ ${FullPathDst} TMP_DST)
    if(NOT TMP_SRC)
      message(ERROR "File not found: ${FullPathSrc}")
    endif()
    if(NOT TMP_DST)
      set(IsChanged 1)
    else()
      if(NOT "${TMP_SRC}" STREQUAL "${TMP_DST}")
        set(IsChanged 1)
      endif()
    endif()
  endif()

  if(IsChanged)
    file(COPY_FILE ${FullPathSrc} ${FullPathDst})
  endif()
endfunction()

function(ResourceSourceGenerationCustomCommand Target OutDir)
  message(STATUS "Generate resources for ${Target} in folder ${OutDir}")

  get_filename_component(FolderName ${OutDir} NAME)

  set(FileNameResourceNameH "${OutDir}/${Target}_${FolderName}_resources.h")
  set(FileNameResourceNameHTMP "${FileNameResourceNameH}TMP")
  file(REMOVE ${FileNameResourceNameHTMP})

  foreach(FileToResource ${ARGN})
    message(STATUS " FileToResource: ${FileToResource}")

    get_filename_component(FileName ${FileToResource} NAME)
    string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

    set(FileNameResourceNameC "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")
    set(FileNameResourceNameCTMP "${FileNameResourceNameC}TMP")
    file(REMOVE ${FileNameResourceNameCTMP})

    file(READ ${FileToResource} FileHEX HEX)
    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " FileHEX ${FileHEX})

    string(CONFIGURE [[
const char* @FunctionName@()\;
]] ContextH)

    string(CONFIGURE [==[
const unsigned char @FunctionName@_Data[] = {@FileHEX@}\;

const char* @FunctionName@()
{
  return reinterpret_cast<const char*>(&@FunctionName@_Data[0])\;
}

]==] ContextC)

    file(APPEND ${FileNameResourceNameHTMP} ${ContextH})
    file(APPEND ${FileNameResourceNameCTMP} ${ContextC})

    FileCopyIsChanged(${FileNameResourceNameCTMP} ${FileNameResourceNameC})

    file(REMOVE ${FileNameResourceNameCTMP})
  endforeach()

  FileCopyIsChanged(${FileNameResourceNameHTMP} ${FileNameResourceNameH})

  file(REMOVE ${FileNameResourceNameHTMP})
endfunction()

function(ResourceSourceGeneration Target RepositoryDir OutDir)
  target_include_directories(${Target} PRIVATE ${OutDir})

  list(REMOVE_DUPLICATES ARGN)

  set(CMakeCutomFile ${OutDir}/EnsureResourceCustomCommand.cmake)

  ResourceSourceGenerationCustomCommand(${Target} ${OutDir} ${ARGN})
  
  file(REMOVE ${CMakeCutomFile})
  file(APPEND ${CMakeCutomFile} "include(EnsureGenerationSourceResource)\n\n")

  get_filename_component(FolderName ${OutDir} NAME)

  target_sources(${Target} PRIVATE "${OutDir}/${Target}_${FolderName}_resources.h")
  source_group("Generated" FILES "${OutDir}/${Target}_${FolderName}_resources.h")

  foreach(FileToResource ${ARGN})
    file(APPEND ${CMakeCutomFile} "list(APPEND FilesRC \"${FileToResource}\")\n")

    get_filename_component(FileName ${FileToResource} NAME)
    string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

    set(FileNameResourceNameC "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")

    target_sources(${Target} PRIVATE ${FileNameResourceNameC})
    source_group("Generated" FILES ${FileNameResourceNameC})

  endforeach()

  file(APPEND ${CMakeCutomFile} "\n")
  string(CONFIGURE [[ResourceSourceGenerationCustomCommand("@Target@" "@OutDir@" ${FilesRC})]] ContextRC @ONLY)

  file(APPEND ${CMakeCutomFile} ${ContextRC})
  file(APPEND ${CMakeCutomFile} "\n")

  add_custom_command(TARGET ${Target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -D"Target=${Target}" -P "${CMakeCutomFile}"
    COMMENT "Generate resources files for ${Target} in ${CMakeCutomFile}"
  )
endfunction()
