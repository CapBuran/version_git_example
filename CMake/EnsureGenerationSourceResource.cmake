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
  list(REMOVE_DUPLICATES ARGN)

  set(FileNameResourceNameH "${OutDir}/${Target}_resource.h")
  set(FileNameResourceNameC "${OutDir}/${Target}_resource.cpp")
  set(FileNameResourceNameHTMP "${FileNameResourceNameH}TMP")
  set(FileNameResourceNameCTMP "${FileNameResourceNameC}TMP")

  file(REMOVE ${FileNameResourceNameHTMP})
  file(REMOVE ${FileNameResourceNameCTMP})

  set(ContextAllH "")
  set(ContextAllC "")

  foreach(FileFullPath ${ARGN})
    message(" FileResource: ${FileFullPath}")

    get_filename_component(FileName ${FileFullPath} NAME)
    string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

    file(READ ${FileFullPath} FileHEX HEX)
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
  endforeach()

  FileCopyIsChanged(${FileNameResourceNameHTMP} ${FileNameResourceNameH})
  FileCopyIsChanged(${FileNameResourceNameCTMP} ${FileNameResourceNameC})

  file(REMOVE ${FileNameResourceNameHTMP})
  file(REMOVE ${FileNameResourceNameCTMP})
  
endfunction()

function(ResourceSourceGeneration Target RepositoryDir OutDir)
  list(REMOVE_DUPLICATES ARGN)

  ResourceSourceGenerationCustomCommand(${Target} ${OutDir} ${ARGN})

  set(FileNameResourceNameList "${OutDir}/${Target}_resource.txt")

  file(REMOVE ${FileNameResourceNameList})

  foreach(FileFullPath ${ARGN})
    file(APPEND ${FileNameResourceNameList} "${FileFullPath}\n")
  endforeach()
  
  set(FileNameResourceNameH "${OutDir}/${Target}_resource.h")
  set(FileNameResourceNameC "${OutDir}/${Target}_resource.cpp")

  target_include_directories(${Target} PRIVATE ${OutDir})
  target_sources(${Target} PRIVATE ${FileNameResourceNameH} ${FileNameResourceNameC})
  source_group("Generated" FILES ${FileNameResourceNameH} ${FileNameResourceNameC})

  set(RecourceFileList "${OutDir}/${Target}_resource.txt")

  FileCopyIsChanged(${RepositoryDir}/CMake/EnsureResourceCustomCommand.cmake ${OutDir}/EnsureResourceCustomCommand.cmake)

  add_custom_command(TARGET ${Target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -D"OutDir=${OutDir}" -D"Target=${Target}" -D"RecourceFileList=${RecourceFileList}" -P "${OutDir}/EnsureResourceCustomCommand.cmake"
    COMMENT "Generate resource file by ${FileNameResourceNameList}"
  )
endfunction()
