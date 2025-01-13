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

function(EmbedVersionInformationCustomCommandBuildVariant RepositoryDir OutDir MessageBuildVariant)
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

  string(CONFIGURE [==[<VersionInfo><FileVersion>@Version@-@PipelineBranchId@.@PipelineId@</FileVersion><ProductVersion>@Version@-@PipelineBranchId@.@PipelineId@</ProductVersion><Timestamp>@CommitterDate@ (@TimeStamp@)</Timestamp><Comment>@AbbreviatedHashSmall@ - @Subject@</Comment></VersionInfo>]==] XML_CONTEXT @ONLY)

  string(CONFIGURE [==[
    git commit hash: @AbbreviatedHashSmall@
    git commit timestamp: @CommitterDate@
    git commit author: @AuthorName@
    git subject: @Subject@
    project path: [@RefName@]@ProjectId@
    build pipeline: @PipelineBranchId@.@PipelineId@
    product version: @Version@
    build date: @BuildDate@]==]
  GEN_CONTEXT @ONLY)

  file(WRITE ${OutDir}/version_gen.xml ${XML_CONTEXT})
  file(WRITE ${OutDir}/gitlab_gen.txt ${GEN_CONTEXT})
  file(WRITE ${OutDir}/git_hash_gen.txt ${AbbreviatedHashSmall})
  file(WRITE ${OutDir}/project_version.txt ${Version})
  file(WRITE ${OutDir}/gitlab_pipeline.txt ${PipelineBranchId}.${PipelineId})
  file(WRITE ${OutDir}/product_build_version.txt ${Version}-${PipelineBranchId}.${PipelineId} ${MessageBuildVariant})

endfunction()

function(EmbedVersionInformationCustomCommand RepositoryDir OutDir)
  EmbedVersionInformationCustomCommandBuildVariant(${RepositoryDir} ${OutDir} " ")
endfunction()

function(EmbedVersionInformationBuildVariantSo Target RepositoryDir MessageBuildVariant IsGenMainVersion)
  ReadVersionFromFile("${RepositoryDir}/VERSION" Version)
  AcquireGitlabPipelineBranchId(PipelineBranchId)

  set_property(TARGET ${Target} PROPERTY VERSION "${Version}.${PipelineBranchId}")
  set_property(TARGET ${Target} PROPERTY SOVERSION "1")

  set(OutDir ${CMAKE_CURRENT_BINARY_DIR}/versiongen)

  EmbedVersionInformationCustomCommandBuildVariant(${RepositoryDir} ${OutDir} ${MessageBuildVariant})

  get_filename_component(FolderName ${OutDir} NAME)

  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${OutDir}/version_gen.xml)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${OutDir}/project_version.txt)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${OutDir}/git_hash_gen.txt)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${OutDir}/gitlab_pipeline.txt)
  GenerateResourceAdditional(${Target} ${OutDir} ${EmptyAdditionalValue} "CPP" ${OutDir}/product_build_version.txt)

  string(CONCAT Additional
    "#define VERSION_INFO_EXPORTS 1^[NewLine]"
    "#ifdef _WIN32^[NewLine]"
    "  #ifdef VERSION_INFO_EXPORTS^[NewLine]"
    "    #define VERSION_INFO_DLLDIR __declspec(dllexport)^[NewLine]"
    "  #else^[NewLine]"
    "    #define VERSION_INFO_DLLDIR __declspec(dllimport)^[NewLine]"
    "  #endif^[NewLine]"
    "#else^[NewLine]"
    "  #ifdef VERSION_INFO_EXPORTS^[NewLine]"
    "    #define VERSION_INFO_DLLDIR __attribute__ ((visibility(^[DoubleQuote]default^[DoubleQuote])))^[NewLine]"
    "  #else^[NewLine]"
    "    #define VERSION_INFO_DLLDIR __attribute__ ((visibility(^[DoubleQuote]default^[DoubleQuote])))^[NewLine]"
    "  #endif^[NewLine]"
    "#endif^[NewLine]"
    "^[NewLine]"
    "VERSION_INFO_DLLDIR const char* ${Target}_gitlab_GetVersion(){^[NewLine]"
    "  return ^[DoubleQuote]${Version}^[DoubleQuote]^[Semicolon]^[NewLine]"
    "}^[NewLine]"
  )

  if(IsGenMainVersion AND UNIX AND NOT APPLE AND NOT WIN32)
    string(CONCAT Additional
      "#include <stdlib.h>^[NewLine]"
      "#include <stdio.h>^[NewLine]"
      "^[NewLine]"
      ${Additional}
      "^[NewLine]"
      "extern const unsigned char BuildVersion[] __attribute__((section(^[DoubleQuote]VERSION_TEXT^[DoubleQuote]))) = {"
      "MACRO_ARRAY}^[Semicolon]^[NewLine]"
      "^[NewLine]"
      "extern const char interp_section[] __attribute__(( section( ^[DoubleQuote].interp^[DoubleQuote] ) ))"
      " = ^[DoubleQuote]/lib64/ld-linux-x86-64.so.2^[DoubleQuote]^[Semicolon]^[NewLine]"
      "extern ^[DoubleQuote]C^[DoubleQuote] void PrintVersion(){^[NewLine]"
      "  printf(^[DoubleQuote]${Target}.so:^[BackSlash]n%s^[BackSlash]n^[DoubleQuote], ${Target}_gitlab_gen_txt())^[Semicolon]^[NewLine]"
      "}^[NewLine]"
    )

    set(ToWriteMainCFile
      "#include <stdlib.h>\n"
      "#include <stdio.h>\n"
      "\n"
      "extern void PrintVersion()\;\n"
      "__attribute__ ((visibility(\"default\")))\n"
      "int main(int argc, char **argv){\n"
      "  PrintVersion()\;\n"
      "  exit(0)\;\n"
      "}\n"
      "__attribute__ ((visibility(\"default\")))\n"
      "int multi_main(void){\n"
      "  PrintVersion()\;\n"
      "  exit(0)\;\n"
      "}\n"
    )
    file(WRITE ${OutDir}/${Target}_main.c ${ToWriteMainCFile})
    target_sources(${Target} PRIVATE ${OutDir}/${Target}_main.c)
    target_link_libraries(${Target} PRIVATE "-Wl,-e,multi_main")
  endif()

  GenerateResourceAdditional(${Target} ${OutDir} ${Additional} "CPP" ${OutDir}/gitlab_gen.txt)

  set(CMakeCutomFile "${OutDir}/EmbedVersion_${Target}.cmake")
  file(REMOVE ${CMakeCutomFile})
  file(APPEND ${CMakeCutomFile} "set(CMAKE_MODULE_PATH" ${CMAKE_CURRENT_FUNCTION_LIST_DIR} ")\n")
  file(APPEND ${CMakeCutomFile} "include(GeneratorResourceCode)\n")
  file(APPEND ${CMakeCutomFile} "include(EmbedVersionInformation)\n")
  file(APPEND ${CMakeCutomFile} "EmbedVersionInformationCustomCommand(\"${RepositoryDir}\" \"${OutDir}\")\n")

  add_custom_command(TARGET ${Target} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_FUNCTION_LIST_DIR} -P "${CMakeCutomFile}"
    COMMENT "Generate version files for ${Target}"
  )

endfunction()

function(EmbedVersionInformationBuildVariant Target RepositoryDir MessageBuildVariant)
  EmbedVersionInformationBuildVariantSo(${Target} ${RepositoryDir} ${MessageBuildVariant} False)
endfunction()

function(EmbedVersionInformation Target RepositoryDir)
  EmbedVersionInformationBuildVariantSo(${Target} ${RepositoryDir} " " False)
endfunction()
