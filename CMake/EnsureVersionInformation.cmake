cmake_minimum_required(VERSION 3.19.8)

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

function(EnsureVersionInformationCustomCommand RepositoryDir OutDir)
  message("EnsureVersionInformationCustomCommand_OutDir: ${OutDir}")

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
  AcquireGitInformationFormat("${RepositoryDir}" "%H"  AbbreviatedHash)
  AcquireGitInformationFormat("${RepositoryDir}" "%ae" AuthorName)
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

  set(XML_CONTEXT 
[==[
    <VersionInfo>
      <FileVersion>
        PipelinVersioneBranchId-PipelineBranchId.PipelineId
      </FileVersion>
      <ProductVersion>
        PipelinVersioneBranchId-PipelineBranchId.PipelineId
      </ProductVersion>
      <Timestamp>
        CommitterDate
      </Timestamp>
      <Comment>
        Subject
      </Comment>
    </VersionInfo>
]==]
  )

  set(GEN_CONTEXT 
[==[
    product version: PipelinVersioneBranchId
    build pipeline: PipelineBranchId.PipelineId
    git commit hash: AbbreviatedHash
    git subject: Subject
    git commit author: AuthorName
    git commit timestamp: CommitterDate
    project path: [RefName]ProjectId
    build date: BuildDate]==]
  )

  string(REPLACE "Subject" ${Subject} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "AuthorName" ${AuthorName} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "AbbreviatedHash" ${AbbreviatedHash} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "CommitterDate" ${CommitterDate} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "ProjectId" ${ProjectId} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "RefName" ${RefName} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "PipelineBranchId" ${PipelineBranchId} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "PipelineId" ${PipelineId} XML_CONTEXT ${XML_CONTEXT})
  string(REPLACE "PipelinVersioneBranchId" ${Version} XML_CONTEXT ${XML_CONTEXT})

  string(REPLACE "Subject" ${Subject} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "AuthorName" ${AuthorName} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "AbbreviatedHash" ${AbbreviatedHash} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "CommitterDate" ${CommitterDate} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "ProjectId" ${ProjectId} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "RefName" ${RefName} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "PipelineBranchId" ${PipelineBranchId} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "PipelineId" ${PipelineId} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "PipelinVersioneBranchId" ${Version} GEN_CONTEXT ${GEN_CONTEXT})
  string(REPLACE "BuildDate" ${BuildDate} GEN_CONTEXT ${GEN_CONTEXT})

  file(WRITE ${OutDir}/version_gen.xml ${XML_CONTEXT})
  file(WRITE ${OutDir}/gitlab_gen.txt ${GEN_CONTEXT})

endfunction()

function(EnsureVersionInformation TargetName RepositoryDir)
  set(OutDir ${CMAKE_CURRENT_BINARY_DIR}/versiongen)

  EnsureVersionInformationCustomCommand(${RepositoryDir} ${OutDir})

  list(APPEND FilesSRC ${OutDir}/version_gen.xml)
  list(APPEND FilesSRC ${OutDir}/gitlab_gen.txt)

  ResourceSourceGeneration(${TargetName} ${RepositoryDir} ${OutDir} ${FilesSRC})
endfunction()
