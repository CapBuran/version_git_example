include(EnsureGenerationSourceResource)

cmake_policy(PUSH)

if(POLICY CMP0007)
  cmake_policy(SET CMP0007 NEW)
endif()

file(READ ${RecourceFileList} Resurses)
string(REPLACE "\n" ";" Resurses ${Resurses})
list(REMOVE_ITEM Resurses "")

cmake_policy(POP)

message("EnsureResourceCustomCommand.cmake ${Resurses}")

ResourceSourceGenerationCustomCommand(${Target} ${OutDir} ${Resurses})
