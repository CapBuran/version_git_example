cmake_minimum_required(VERSION 3.17.0)

function(ReadVersionFromFile file version)
  if(EXISTS ${file})
    file(STRINGS ${file} OutVar LIMIT_COUNT 1)
    string(REPLACE "\n" "" OutVar ${OutVar})
    set(${version} ${OutVar} PARENT_SCOPE)
  else()
    set(${version} "0.0" PARENT_SCOPE)
  endif()
endfunction()

function(AcquireGitInformationFormat Path Format GitInfo)
  execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --format=${Format}
    ENCODING UTF8
    OUTPUT_VARIABLE OutVar
    WORKING_DIRECTORY ${Path}
    TIMEOUT 5
  )
  string(REPLACE "\n" "" OutVar ${OutVar})
  set(${GitInfo} ${OutVar} PARENT_SCOPE)
endfunction()

function(AcquireGitlabPipelineId id)
  if(DEFINED ENV{CI_PIPELINE_ID})
    set(${id} $ENV{CI_PIPELINE_ID} PARENT_SCOPE)
  else()
    set(${id} "999" PARENT_SCOPE)
  endif()
endfunction()

function(AcquireGitlabPipelineBranchId id)
  if(DEFINED ENV{CI_PIPELINE_BRANCH_ID})
    set(${id} $ENV{CI_PIPELINE_BRANCH_ID} PARENT_SCOPE)
  else()
    set(${id} "9" PARENT_SCOPE)
  endif()
endfunction()

function(AcquireProjectId id)
  if(DEFINED ENV{CI_PROJECT_DIR})
    set(${id} $ENV{CI_PROJECT_DIR} PARENT_SCOPE)
  else()
    set(${id} "local-project" PARENT_SCOPE)
  endif()
endfunction()

function(AcquireRefName id)
  if(DEFINED ENV{CI_COMMIT_REF_NAME})
    set(${id} $ENV{CI_COMMIT_REF_NAME} PARENT_SCOPE)
  else()
    set(${id} "none" PARENT_SCOPE)
  endif()
endfunction()

function(EmbedVersionInformationCustomCommand RepositoryDir OutDir)
  if(NOT GIT_FOUND)
    find_package(Git)
  else()
    set(GIT_EXECUTABLE git CACHE)
  endif()

  ReadVersionFromFile("${RepositoryDir}/VERSION" Version)
  AcquireGitlabPipelineBranchId(PipelineBranchId)
  AcquireProjectId(ProjectId)
  AcquireRefName(RefName)
  AcquireGitlabPipelineId(PipelineId)
  AcquireGitInformationFormat("${RepositoryDir}" "%ai" CommitterDate)
  AcquireGitInformationFormat("${RepositoryDir}" "%H"  AbbreviatedHashBig)
  AcquireGitInformationFormat("${RepositoryDir}" "%h"  AbbreviatedHashSmall)
  AcquireGitInformationFormat("${RepositoryDir}" "%ct" TimeStamp)
  AcquireGitInformationFormat("${RepositoryDir}" "%an" AuthorName)
  AcquireGitInformationFormat("${RepositoryDir}" "%s"  Subject)

  if(ENABLE_TEST_BUILD)
    set(Version "${Version} - this is test build")
  endif()

  string(TIMESTAMP Date "%Y-%m-%d")
  string(TIMESTAMP Time "%H:%M:%S")
  string(TIMESTAMP TimeZone "%z")

  if("${TimeZone}" STREQUAL "%z")
    set(TimeZone "+0300")
  endif()

  set(BuildDate "${Date} ${Time} ${TimeZone}")

  string(CONFIGURE [==[
<VersionInfo>
  <FileVersion>@Version@</FileVersion>
  <ProductVersion>@Version@</ProductVersion>
  <Timestamp>@CommitterDate@ (@TimeStamp@)</Timestamp>
  <Comment>@AbbreviatedHashSmall@ - @Subject@</Comment>
</VersionInfo>
]==] XML_CONTEXT @ONLY)

  string(CONFIGURE [==[
    product version: @Version@
    build pipeline: @PipelineBranchId@.@PipelineId@
    git commit hash: @AbbreviatedHashBig@
    git subject: @Subject@
    git commit author: @AuthorName@
    git commit timestamp: @CommitterDate@
    project path: [@RefName@]@ProjectId@
    build date: @BuildDate@]==]
GEN_CONTEXT @ONLY)

  file(WRITE ${OutDir}/version_gen.xml ${XML_CONTEXT})
  file(WRITE ${OutDir}/gitlab_gen.txt ${GEN_CONTEXT})

endfunction()

function(EmbedVersionInformation Target RepositoryDir)
  ReadVersionFromFile("${RepositoryDir}/VERSION" Version)
  AcquireGitlabPipelineBranchId(PipelineBranchId)

  set_property(TARGET ${Target} PROPERTY VERSION "${Version}.${PipelineBranchId}")
  set_property(TARGET ${Target} PROPERTY SOVERSION "1")

  set(OutDir ${CMAKE_CURRENT_BINARY_DIR}/versiongen)

  EmbedVersionInformationCustomCommand(${RepositoryDir} ${OutDir})

  get_filename_component(FolderName ${OutDir} NAME)

  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} ${OutDir}/gitlab_gen.txt)

  string(CONCAT Additional
    "const char* ${Target}_gitlab_GetVersion(){^[NewLine]"
    "  return ^[DoubleQuote]${Version}^[DoubleQuote]^[Semicolon]^[NewLine]"
    "}^[NewLine]"
  )
if(UNIX AND NOT APPLE AND NOT WIN32)
  string(CONCAT Additional
    ${Additional}
    "#include <stdlib.h>^[NewLine]"
    "#include <stdio.h>^[NewLine]"
    "extern const unsigned char BuildVersion[] __attribute__((section(^[DoubleQuote]VERSION_TEXT^[DoubleQuote]))) = {^[NewLine]"
    "^[HEXFILE] }^[Semicolon]^[NewLine]"
    "extern const char interp_section[] __attribute__(( section( ^[DoubleQuote].interp^[DoubleQuote] ) ))^[NewLine]"
    "  = ^[DoubleQuote]/lib64/ld-linux-x86-64.so.2^[DoubleQuote]^[Semicolon]^[NewLine]"
    "__attribute__ ((visibility(^[DoubleQuote]default^[DoubleQuote])))^[NewLine]"
    "void print_version() {^[NewLine]"
    "  exit(0)^[Semicolon]^[NewLine]"
    "}^[NewLine]"
  )
endif()
  GenerateResourceAdditional(${Target} ${OutDir} ${Additional} ${OutDir}/version_gen.xml)

  set(CMakeCutomFile "${OutDir}/EmbedVersion_${Target}.cmake")
  file(REMOVE ${CMakeCutomFile})
  file(APPEND ${CMakeCutomFile} "include(EmbedVersionInformation)\n")

  file(APPEND ${CMakeCutomFile} "EmbedVersionInformationCustomCommand(\"${RepositoryDir}\" \"${OutDir}\")\n")

  add_custom_command(TARGET ${Target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -D"CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" -P "${CMakeCutomFile}"
    COMMENT "Generate version files for ${Target}"
  )

endfunction()
