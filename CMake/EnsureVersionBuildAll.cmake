cmake_policy(PUSH)

if(POLICY CMP0007)
  cmake_policy(SET CMP0007 NEW)
endif()

file(READ ${RecourceFile} Resurses)
string(REPLACE "\\\n" "" Resurses ${Resurses})
string(REPLACE "\n" ";" Resurses ${Resurses})
list(REMOVE_ITEM Resurses "")

cmake_policy(POP)

foreach(FileFullPath ${Resurses})
  message("FileResource: ${FileFullPath}")
endforeach()

include(EnsureVersionInformation)
include(EnsureGenerationSourceResourceCode)

list(REMOVE_DUPLICATES Resurses)

set(FileNameResourceNameH "${OutDir}/${Target}_resource.h")
set(FileNameResourceNameC "${OutDir}/${Target}_resource.cpp")
set(FileNameResourceNameHTMP "${FileNameResourceNameH}TMP")
set(FileNameResourceNameCTMP "${FileNameResourceNameC}TMP")

file(REMOVE ${FileNameResourceNameHTMP})
file(REMOVE ${FileNameResourceNameCTMP})

set(ContextAllH "")
set(ContextAllC "")

foreach(FileFullPath ${Resurses})
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

set(VersionSources ${FileNameResourceNameH} ${FileNameResourceNameC})

