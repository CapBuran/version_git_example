cmake_minimum_required(VERSION 3.21.0)

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

function(ResourceSourceGenerationCustomCommand Target OutDir Additional FileToResource)
  message(STATUS "Generate resources for ${Target} in folder ${OutDir} for ${FileToResource}")

  get_filename_component(FolderName ${OutDir} NAME)

  get_filename_component(FileName ${FileToResource} NAME)
  string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

  set(FileNameResourceNameC "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")
  set(FileNameResourceNameCTMP "${FileNameResourceNameC}{SuffixTMP}")
  file(REMOVE ${FileNameResourceNameCTMP})

  file(READ ${FileToResource} FileHEX HEX)
  string(REGEX REPLACE
    "([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])"
    "  \\1\\\\\\n  " FileHEX ${FileHEX}
  )
  string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " FileHEX ${FileHEX})
  string(REPLACE "    " "  " FileHEX ${FileHEX})

  string(CONFIGURE [==[
#define MACRO_ARRAY \
@FileHEX@

static const unsigned char @FunctionName@_Data[] = { MACRO_ARRAY }\;

static const char @FunctionName@_ZeroChar = '\0'\;

const char* @FunctionName@()
{
  return reinterpret_cast<const char*>(&@FunctionName@_Data[0])\;
}

unsigned long long @FunctionName@_size()
{
  return sizeof(@FunctionName@_Data)\;
}

]==] ContextC)

  file(APPEND ${FileNameResourceNameCTMP} ${ContextC})

  if(NOT ${Additional} STREQUAL ${EmptyAdditionalValue})
    string(REPLACE "^[SingleQuote]" "'" Additional ${Additional})
    string(REPLACE "^[DoubleQuote]" "\"" Additional ${Additional})
    string(REPLACE "^[BackSlash]" "\\" Additional ${Additional})
    string(REPLACE "^[NewLine]" "\n" Additional ${Additional})
    string(REPLACE "^[Tab]" "\t" Additional ${Additional})
    string(REPLACE "^[Dollar]" "$" Additional ${Additional})
    string(REPLACE "^[Section]" "$" Additional ${Additional})
    string(REPLACE "^[Semicolon]" "\;" Additional ${Additional})
    file(APPEND ${FileNameResourceNameCTMP} ${Additional})
  endif()

  FileCopyIsChanged(${FileNameResourceNameCTMP} ${FileNameResourceNameC})

  file(REMOVE ${FileNameResourceNameCTMP})
endfunction()

function(ResourceSourceGenerationAdditional Target RepositoryDir OutDir Additional)
  list(REMOVE_DUPLICATES ARGN)

  list(LENGTH ARGN LengyhARGN)
  if(${LengyhARGN} EQUAL 0)
    return()
  endif()

  target_include_directories(${Target} PRIVATE ${OutDir})

  get_filename_component(FolderName ${OutDir} NAME)

  set(FileNameResourceNameH "${OutDir}/${Target}_${FolderName}.h")
  set(FileNameResourceNameHTMP "${FileNameResourceNameH}${SuffixTMP}")

  set(EnsureGenerationSourceResourceCopyCACHE "")

  if(EnsureGenerationSourceResourceCACHE)
    foreach(HeaderFile ${EnsureGenerationSourceResourceCACHE})
      list(APPEND EnsureGenerationSourceResourceCopyCACHE ${HeaderFile})
    endforeach()
  endif()

  list(APPEND EnsureGenerationSourceResourceCopyCACHE ${FileNameResourceNameH})

  set(EnsureGenerationSourceResourceCACHE ${EnsureGenerationSourceResourceCopyCACHE} CACHE STRING "11" FORCE)

  foreach(FileToResource ${ARGN})
    get_filename_component(FileName ${FileToResource} NAME)

    ResourceSourceGenerationCustomCommand(${Target} ${OutDir} ${Additional} ${FileToResource})

    set(CMakeCutomFile ${OutDir}/EnsureResourceCustomCommandFor_${FileName}.cmake)
    set(FileNameResourceNameC "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")

    string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

    string(CONFIGURE [[
const char* @FunctionName@()
unsigned long long @FunctionName@_size()
]] ContextH)
    file(APPEND ${FileNameResourceNameHTMP} ${ContextH})

    file(REMOVE ${CMakeCutomFile})
    file(APPEND ${CMakeCutomFile} "include(EnsureGenerationSourceResource)\n")
    file(APPEND ${CMakeCutomFile} "ResourceSourceGenerationCustomCommand(\"${Target}\" \"${OutDir}\" \"${Additional}\" \"${FileToResource}\")\n")

    target_sources(${Target} PRIVATE ${FileNameResourceNameC})
    source_group("Generated" FILES ${FileNameResourceNameC})

    add_custom_command(
      OUTPUT ${FileNameResourceNameC}
      COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -P "${CMakeCutomFile}"
      COMMENT "Generate resources file ${FileName} for ${Target} in ${CMakeCutomFile}"
      DEPENDS ${FileToResource}
    )
  endforeach()

  target_sources(${Target} PRIVATE ${FileNameResourceNameH})
  source_group("Generated" FILES ${FileNameResourceNameH})
endfunction()

function(ResourceSourceGeneration Target RepositoryDir OutDir)
  ResourceSourceGenerationAdditional(${Target} ${RepositoryDir} ${OutDir} ${EmptyAdditionalValue} ${ARGN})
endfunction()

function(ResourceSourceGenerationFinalize)
  file(REMOVE ${DDD})
  if(EnsureGenerationSourceResourceCACHE)
    list(REMOVE_DUPLICATES EnsureGenerationSourceResourceCACHE)
    foreach(HeaderFile ${EnsureGenerationSourceResourceCACHE})
      if(EXISTS "${HeaderFile}${SuffixTMP}")
        file(STRINGS "${HeaderFile}${SuffixTMP}" ContentH)
        list(REMOVE_DUPLICATES ContentH)
        foreach(Line ${ContentH})
          file(APPEND "${HeaderFile}${SuffixTMP}${SuffixTMP}" "${Line};\n")
        endforeach()
        FileCopyIsChanged("${HeaderFile}${SuffixTMP}${SuffixTMP}" ${HeaderFile})
      endif()
      file(REMOVE "${HeaderFile}${SuffixTMP}")
      file(REMOVE "${HeaderFile}${SuffixTMP}${SuffixTMP}")
    endforeach()
    unset(EnsureGenerationSourceResourceCACHE CACHE)
  endif()
endfunction()
