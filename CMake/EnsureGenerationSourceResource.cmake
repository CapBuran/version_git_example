
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

function(ResourceSourceGenerationCustomCommand Target OutDir FileToResource)
  message(STATUS "Generate resources for ${Target} in folder ${OutDir} for ${FileToResource}")

  get_filename_component(FolderName ${OutDir} NAME)

  get_filename_component(FileName ${FileToResource} NAME)
  string(MAKE_C_IDENTIFIER "${Target}_${FileName}" FunctionName)

  set(FileNameResourceNameC "${OutDir}/${Target}_${FolderName}_${FileName}.cpp")
  set(FileNameResourceNameCTMP "${FileNameResourceNameC}TMP")
  file(REMOVE ${FileNameResourceNameCTMP})

  file(READ ${FileToResource} FileHEX HEX)
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3, 0x\\4, 0x\\5, 0x\\6, 0x\\7, 0x\\8, \\n" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3, 0x\\4, 0x\\5, 0x\\6, 0x\\7" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3, 0x\\4, 0x\\5, 0x\\6" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3, 0x\\4, 0x\\5" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3, 0x\\4" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2, 0x\\3" FileHEX ${FileHEX}
  )
  string(
    REGEX REPLACE
    "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])"
    "Y0x\\1, 0x\\2" FileHEX ${FileHEX}
    )
  string(
    REGEX REPLACE
    "\n([0-9a-f][0-9a-f])"
    "\nY0x\\1" FileHEX ${FileHEX}
  )
  string(REPLACE "Y" "  " FileHEX ${FileHEX} )

  string(CONFIGURE [==[
const unsigned char @FunctionName@_Data[] = {
@FileHEX@
}\;

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

  FileCopyIsChanged(${FileNameResourceNameCTMP} ${FileNameResourceNameC})

  file(REMOVE ${FileNameResourceNameCTMP})
endfunction()

function(ResourceSourceGeneration Target RepositoryDir OutDir)
  list(REMOVE_DUPLICATES ARGN)

  target_include_directories(${Target} PRIVATE ${OutDir})

  get_filename_component(FolderName ${OutDir} NAME)

  set(FileNameResourceNameH "${OutDir}/${Target}_${FolderName}_resources.h")
  set(FileNameResourceNameHTMP "${FileNameResourceNameH}TMP")
  file(REMOVE ${FileNameResourceNameHTMP})
  
  if(EXISTS ${FileNameResourceNameH})
    file(COPY_FILE ${FileNameResourceNameH} ${FileNameResourceNameHTMP})
  endif()

  foreach(FileToResource ${ARGN})
    get_filename_component(FileName ${FileToResource} NAME)

    ResourceSourceGenerationCustomCommand(${Target} ${OutDir} ${FileToResource})

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
    file(APPEND ${CMakeCutomFile} "ResourceSourceGenerationCustomCommand(\"${Target}\" \"${OutDir}\" \"${FileToResource}\")\n")

    target_sources(${Target} PRIVATE ${FileNameResourceNameC})
    source_group("Generated" FILES ${FileNameResourceNameC})

    add_custom_command(
      OUTPUT ${FileNameResourceNameC}
      COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -P "${CMakeCutomFile}"
      COMMENT "Generate resources file ${FileName} for ${Target} in ${CMakeCutomFile}"
      DEPENDS ${FileToResource}
    )
  endforeach()

  file(STRINGS ${FileNameResourceNameHTMP} ContentH)

  foreach(Line ${ContentH})
    string(REPLACE ";" "" Line ${Line})
    string(REPLACE "\\" "" Line ${Line})
    list(APPEND ContentNewH ${Line})
  endforeach()
  list(REMOVE_DUPLICATES ContentNewH)
  list(SORT ContentNewH)
  file(REMOVE ${FileNameResourceNameHTMP})
  foreach(Line ${ContentNewH})
    file(APPEND ${FileNameResourceNameHTMP} "${Line};\n")
  endforeach()

  target_sources(${Target} PRIVATE ${FileNameResourcesNameH})
  source_group("Generated" FILES ${FileNameResourcesNameH})

  FileCopyIsChanged(${FileNameResourceNameHTMP} ${FileNameResourceNameH})
  file(REMOVE ${FileNameResourceNameHTMP})
endfunction()
