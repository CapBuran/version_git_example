cmake_minimum_required(VERSION 3.11.0)

set(EmptyAdditionalValue "EmPtY")
set(SuffixTMP "TMP")

#Replace for symbols:
#^[SingleQuote] '
#^[DoubleQuote] "
#^[BackSlash] \
#^[NewLine] /n
#^[Tab)] /t
#^[Dollar] $
#^[Section] $
#^[Semicolon] ;

function(FileCopyIsChanged FullPathSrc FullPathDst)
  set(IsChanged 0)

  if(NOT EXISTS ${FullPathDst})
    set(IsChanged 1)
  else()
    file(READ ${FullPathSrc} TMP_SRC)
    file(READ ${FullPathDst} TMP_DST)
    if(NOT TMP_SRC)
      message(FATAL_ERROR "File not found: ${FullPathSrc}")
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
    configure_file(${FullPathSrc} ${FullPathDst} COPYONLY)
    message(STATUS "Update file: ${FullPathDst}")
  endif()
endfunction()

function(GenerateResourceCustomCommand Target OutDir Additional Language FileToResource)

  get_filename_component(FolderName ${OutDir} NAME)

  get_filename_component(FileName ${FileToResource} NAME)
  string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

  set(FileNameResourceName "")

  if("${Language}" STREQUAL "C")
    set(FileNameResourceName "${OutDir}/${Target}_${FolderName}_${FileName}.c")
  elseif("${Language}" STREQUAL "CPP")
    set(FileNameResourceName "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")
  else()
    message(ERROR "programming language not supported: ${Language}")
  endif()
 
  set(FileNameResourceNameTMP "${FileNameResourceName}${SuffixTMP}")

  file(REMOVE ${FileNameResourceNameTMP})

  file(READ ${FileToResource} FileHEX HEX)
  set(FileHEX ${FileHEX}Y)
  string(REGEX REPLACE
    "([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])"
    "  \\1\\\\\\n  " FileHEX ${FileHEX}
  )
  string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " FileHEX ${FileHEX})
  string(REPLACE "    " "  " FileHEX ${FileHEX})
  string(REPLACE "Y" "0x00" FileHEX ${FileHEX})

  set(OnlyHEX ${FileHEX})

  string(CONFIGURE [==[
#define MACRO_ARRAY \
@FileHEX@

static const unsigned char @FunctionName@_Data[] = { MACRO_ARRAY }\;

const char* @FunctionName@()
{
  return (const char*)(&@FunctionName@_Data[0])\;
}

unsigned long long @FunctionName@_size()
{
  return sizeof(@FunctionName@_Data) - 1\;
}

]==] Content)

  file(APPEND ${FileNameResourceNameTMP} ${Content})

  if(NOT ${Additional} STREQUAL ${EmptyAdditionalValue})
    string(REPLACE "^[SingleQuote]" "'" Additional ${Additional})
    string(REPLACE "^[DoubleQuote]" "\"" Additional ${Additional})
    string(REPLACE "^[BackSlash]" "\\" Additional ${Additional})
    string(REPLACE "^[NewLine]" "\n" Additional ${Additional})
    string(REPLACE "^[Tab]" "\t" Additional ${Additional})
    string(REPLACE "^[Dollar]" "$" Additional ${Additional})
    string(REPLACE "^[Section]" "$" Additional ${Additional})
    string(REPLACE "^[HEXFILE]" ${OnlyHEX} Additional ${Additional})
    string(REPLACE "^[Semicolon]" "\;" Additional ${Additional})
    file(APPEND ${FileNameResourceNameTMP} ${Additional})
  endif()

  FileCopyIsChanged(${FileNameResourceNameTMP} ${FileNameResourceName})

  file(REMOVE ${FileNameResourceNameTMP})
endfunction()

function(GenerateResourceAdditional Target OutDir Additional Language)
  list(REMOVE_DUPLICATES ARGN)

  list(LENGTH ARGN LengyhARGN)
  if(${LengyhARGN} EQUAL 0)
    return()
  endif()

  target_include_directories(${Target} PRIVATE ${OutDir})

  get_filename_component(FolderName ${OutDir} NAME)

  set(FileNameResourceNameH "${OutDir}/${Target}_${FolderName}_${Language}.h")
  set(FileNameResourceNameHTMP "${FileNameResourceNameH}${SuffixTMP}")

  set(ResourceHeadersListCopyCache "")

  list(APPEND ResourceHeadersListCopyCache ${FileNameResourceNameH})

  if("${Language}" STREQUAL "C")
    if(ResourceHeadersListCacheC)
      foreach(HeaderFile ${ResourceHeadersListCacheC})
        list(APPEND ResourceHeadersListCopyCache ${HeaderFile})
      endforeach()
    endif()
    set(ResourceHeadersListCacheC ${ResourceHeadersListCopyCache} CACHE STRING "11" FORCE)
  elseif("${Language}" STREQUAL "CPP")
    if(ResourceHeadersListCacheCPP)
      foreach(HeaderFile ${ResourceHeadersListCacheCPP})
        list(APPEND ResourceHeadersListCopyCache ${HeaderFile})
      endforeach()
    endif()
    set(ResourceHeadersListCacheCPP ${ResourceHeadersListCopyCache} CACHE STRING "11" FORCE)
  else()
    message(FATAL_ERROR "programming language not supported: ${Language}")
  endif()

  foreach(FileToResource ${ARGN})
    get_filename_component(FileName ${FileToResource} NAME)

    set(CMakeCutomFile ${OutDir}/GenerateResourceCustomCommandFor_${FileName}.cmake)

    set(FileNameResourceName "")

    if("${Language}" STREQUAL "C")
       set(FileNameResourceName "${OutDir}/${Target}_${FolderName}_${FileName}.c")
    elseif("${Language}" STREQUAL "CPP")
      set(FileNameResourceName "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")
    else()
      message(FATAL_ERROR "programming language not supported: ${Language}")
    endif()

    string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

    string(CONFIGURE [[
const char* @FunctionName@()
unsigned long long @FunctionName@_size()
]] ContentH)
    file(APPEND ${FileNameResourceNameHTMP} ${ContentH})

    GenerateResourceCustomCommand(${Target} ${OutDir} ${Additional} ${Language} ${FileToResource})

    file(REMOVE ${CMakeCutomFile})
    file(APPEND ${CMakeCutomFile} "include(GeneratorResourceCode)\n")
    file(APPEND ${CMakeCutomFile} "GenerateResourceCustomCommand(\"${Target}\" \"${OutDir}\" \"${Additional}\" \"${Language}\" \"${FileToResource}\")\n")

    target_sources(${Target} PRIVATE ${FileToResource})
    target_sources(${Target} PRIVATE ${FileNameResourceName})
    source_group("Generated" FILES ${FileNameResourceName})

    add_custom_command(
      OUTPUT ${FileNameResourceName}
      COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -P "${CMakeCutomFile}"
      DEPENDS ${FileToResource}
    )
  endforeach()

  target_sources(${Target} PRIVATE ${FileNameResourceNameH} ${FileNameResourceName})
  source_group("Generated" FILES ${FileNameResourceNameH} ${FileNameResourceName})
endfunction()

function(GenerateResource Target OutDir Language)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} ${Language} ${ARGN})
endfunction()

function(GenerateResourceC Target OutDir)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "C" ${ARGN})
endfunction()

function(GenerateResourceCPP Target OutDir)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${ARGN})
endfunction()

function(GenerateResourceFinalize)
  if(ResourceHeadersListCacheC)
    list(REMOVE_DUPLICATES ResourceHeadersListCacheC)
    foreach(HeaderFile ${ResourceHeadersListCacheC})
      if(EXISTS "${HeaderFile}${SuffixTMP}")
        file(STRINGS "${HeaderFile}${SuffixTMP}" ContentH)
        list(REMOVE_DUPLICATES ContentH)
        file(WRITE "${HeaderFile}${SuffixTMP}${SuffixTMP}" "#ifdef __cplusplus\n")
        file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "extern \"C\"\n{\n")
        file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "#endif\n")
        foreach(Line ${ContentH})
          file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "${Line};\n")
        endforeach()
        file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "#ifdef __cplusplus\n")
        file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "}\n")
        file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "#endif\n")
        FileCopyIsChanged("${HeaderFile}${SuffixTMP}${SuffixTMP}" ${HeaderFile})
      endif()
      file(REMOVE "${HeaderFile}${SuffixTMP}")
      file(REMOVE "${HeaderFile}${SuffixTMP}${SuffixTMP}")
    endforeach()
    unset(ResourceHeadersListCacheC CACHE)
  endif()
  if(ResourceHeadersListCacheCPP)
    list(REMOVE_DUPLICATES ResourceHeadersListCacheCPP)
    foreach(HeaderFile ${ResourceHeadersListCacheCPP})
      if(EXISTS "${HeaderFile}${SuffixTMP}")
        file(STRINGS "${HeaderFile}${SuffixTMP}" ContentH)
        list(REMOVE_DUPLICATES ContentH)
        file(WRITE "${HeaderFile}${SuffixTMP}${SuffixTMP}" "\n")
        foreach(Line ${ContentH})
          file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "${Line};\n")
        endforeach()
        FileCopyIsChanged("${HeaderFile}${SuffixTMP}${SuffixTMP}" ${HeaderFile})
      endif()
      file(REMOVE "${HeaderFile}${SuffixTMP}")
      file(REMOVE "${HeaderFile}${SuffixTMP}${SuffixTMP}")
    endforeach()
    unset(ResourceHeadersListCacheCPP CACHE)
  endif()
endfunction()
