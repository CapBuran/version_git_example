include(EnsureVersionInformation)
include(EnsureGenerationSourceResourceCode)

cmake_policy(PUSH)

if(POLICY CMP0007)
  cmake_policy(SET CMP0007 NEW)
endif()

file(READ ${RecourceFileList} Resurses)
string(REPLACE "\\\n" "" Resurses ${Resurses})
string(REPLACE "\n" ";" Resurses ${Resurses})
list(REMOVE_ITEM Resurses "")

cmake_policy(POP)

EnsureVersionInformationCustomCommand(${RepositoryDir} ${OutDir})

set(VersionSources "")

ResourceSourceCodeGenerationCustomCommand(${Target} ${OutDir} ${Resurses} ${VersionSources})

message("VersionSources: ${VersionSources}")
