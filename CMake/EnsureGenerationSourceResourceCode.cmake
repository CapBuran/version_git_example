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

function(ResourceSourceCodeGeneration Target OutDir)

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

  set(VersionSources ${FileNameResourceNameH} ${FileNameResourceNameC})

  target_include_directories(${Target} PRIVATE ${OutDir})
  target_sources(${Target} PRIVATE ${VersionSources})
  source_group("Generated" FILES ${VersionSources})

endfunction()
