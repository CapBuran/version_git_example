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

function(ResourceSourceCodeGenerationCustomCommand Target OutDir VersionSources)
  message("ARGN1: ${ARGN}")
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
    message("FileResource: ${FileFullPath}")

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
  
  set(VersionSources1 ${FileNameResourceNameH} ${FileNameResourceNameC})
  set(VersionSources ${VersionSources1} PARENT_SCOPE)
endfunction()

function(ResourceSourceCodeGenerationAddCustomCommand Target RepositoryDir OutDir)
  message("ResourceSourceCodeGenerationAddCustomCommand: RepositoryDir111: ${RepositoryDir}")

  set(RecourceFileList "${OutDir}/${Target}_resource.txt")
  add_custom_command(TARGET ${Target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -D"OutDir=${OutDir}" -D"Target=${Target}" -D"RepositoryDir=${RepositoryDir}" -D"RecourceFileList=${RecourceFileList}" -P "${CMAKE_CURRENT_SOURCE_DIR}/CMake/EnsureVersionCustomCommand.cmake"
    COMMENT "Generate resource file by ${FileNameResourceNameList}"
  )
endfunction()

function(ResourceSourceCodeGeneration Target RepositoryDir OutDir)
  list(REMOVE_DUPLICATES ARGN)

  message("ResourceSourceCodeGeneration: RepositoryDir111: ${RepositoryDir}")

  set(VersionSources "")
  ResourceSourceCodeGenerationCustomCommand(${Target} ${OutDir} ${ARGN} ${VersionSources})

  set(FileNameResourceNameList "${OutDir}/${Target}_resource.txt")

  file(REMOVE ${FileNameResourceNameList})

  foreach(FileFullPath ${ARGN})
    file(APPEND ${FileNameResourceNameList} "${FileFullPath}\n")
  endforeach()
  
  message("ResourceSourceCodeGeneration VersionSources: ${VersionSources}")

  target_include_directories(${Target} PRIVATE ${OutDir})
  target_sources(${Target} PRIVATE ${VersionSources})
  source_group("Generated" FILES ${VersionSources})

  ResourceSourceCodeGenerationAddCustomCommand(${Target} ${RepositoryDir} ${OutDir})
endfunction()
