cmake_minimum_required(VERSION 3.19.8)

function(ReadVersionFromFile file version)
  if(EXISTS ${file})
     file(STRINGS ${file} outvar LIMIT_COUNT 1)
    set(${version} ${outvar} PARENT_SCOPE)
  else()
    set(${version} "1.0" PARENT_SCOPE)
  endif()
endfunction()

function(AcquireGitInformation path GitInfo)
  execute_process(
    COMMAND git log -1 --format="AAA%aiBBB%hCCC%an\(%ae\)DDD%sEEE"
    ENCODING UTF8
    OUTPUT_VARIABLE outvar
    WORKING_DIRECTORY ${path}
    TIMEOUT 5
  )
  set(${GitInfo} ${outvar} PARENT_SCOPE)
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

function(FileWriteIsChanged path context)
  set(IsChanged 0)

  if(NOT EXISTS ${path})
    set(IsChanged 1)
  else()
    file(READ ${path} TMP)
    if(NOT TMP)
      set(IsChanged 1)
    else()
      if(NOT ${TMP} STREQUAL ${context})
        set(IsChanged 1)
      endif()
    endif()
  endif()

  if(IsChanged)
    file(REMOVE ${path})
    file(WRITE ${path} ${context})
  endif()
endfunction()


		# XXX, ${buildinfo_h_fake} is used here,
	# because we rely on that file being detected as missing
	# every build so that the real header "buildinfo.h" is updated.
	#
	# Keep this until we find a better way to resolve!

	set(buildinfo_h_real "${CMAKE_CURRENT_BINARY_DIR}/buildinfo.h")
	set(buildinfo_h_fake "${CMAKE_CURRENT_BINARY_DIR}/buildinfo.h_fake")

	if(EXISTS ${buildinfo_h_fake})
		message(FATAL_ERROR "File \"${buildinfo_h_fake}\" found, this should never be created, remove!")
	endif()

	# a custom target that is always built
	add_custom_target(buildinfo ALL
		DEPENDS ${buildinfo_h_fake})

	# creates buildinfo.h using cmake script
	add_custom_command(
		OUTPUT
			${buildinfo_h_fake}  # ensure we always run
			${buildinfo_h_real}
		COMMAND ${CMAKE_COMMAND}
		-DSOURCE_DIR=${CMAKE_SOURCE_DIR}
		# overrides only used when non-empty strings
		-DBUILD_DATE=${BUILDINFO_OVERRIDE_DATE}
		-DBUILD_TIME=${BUILDINFO_OVERRIDE_TIME}
		-P ${CMAKE_SOURCE_DIR}/build_files/cmake/buildinfo.cmake)

	# buildinfo.h is a generated file
	set_source_files_properties(
		${buildinfo_h_real}
		PROPERTIES GENERATED TRUE
		HEADER_FILE_ONLY TRUE)

	unset(buildinfo_h_real)
	unset(buildinfo_h_fake)

function(Compare2Files file1 file2)
  execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files ${file1} ${file2} RESULT_VARIABLE Compare2Files)
  if( Compare2Files EQUAL 0)
    set(${Compare2FilesRet} 0)
    message("The files are identical.")
  elseif( Compare2Files EQUAL 1)
    set(${Compare2FilesRet} 1)
    message("The files are different.")
  else()
    set(${Compare2FilesRet} 1)
    message("Error while comparing the files.")
  endif()
endfunction()

function(Compare2Files file1 file2)
  add_custom_command(
    OUTPUT file1
    COMMAND echo touching file1
    COMMAND touch file1
    DEPENDS file2)
  add_custom_target(dep ALL DEPENDS file1 file2)

# this command re-touches file2 after dep target is "built"
# and thus forces its rebuild
 ADD_CUSTOM_COMMAND(TARGET dep
          POST_BUILD
          COMMAND echo touching file2
          COMMAND touch file2
)
endfunction()

function(create_source_version_files target_name output_dir file_xml file_gen)

  file(READ ${output_dir}/${file_xml} file_input_xml HEX)
  string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," file_input_xml ${file_input_xml})

  file(READ ${output_dir}/${file_gen} file_input_gen HEX)
  string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," file_input_gen ${file_input_gen})

  set(filedata_to_write_static_h
  [==[
unsigned int @target_name@_VersionGenSizeStatic()\;

unsigned int @target_name@_VersionXMLSizeStatic()\;

const char* @target_name@_VersionGenStatic()\;

const char* @target_name@_VersionXMLStatic()\;
]==]
  )

  set(filedata_to_write_static_cpp
  [==[
const unsigned char @target_name@_XML[] = { @file_input_xml@ }\;

const unsigned char @target_name@_Gen[] = { @file_input_gen@ }\;

const char date[] =  __DATE__ " " __TIME__\;

char result_gen[sizeof(@target_name@_Gen) + sizeof(date)]\;

unsigned int @target_name@_VersionXMLSizeStatic() {
  return sizeof(@target_name@_XML)\;
}

unsigned int @target_name@_VersionGenSizeStatic() {
  return sizeof(@target_name@_Gen) + sizeof(date)\;
}

const char* @target_name@_VersionXMLStatic() {
 return reinterpret_cast<const char*>(&@target_name@_XML[0])\;
}

const char* @target_name@_VersionGenStatic() {
 for (int i = 0\; i < sizeof(@target_name@_Gen)\; i++)
    result_gen[i] = @target_name@_Gen[i]\;
  for (int i = 0\; i < sizeof(date)\; i++)
    result_gen[sizeof(@target_name@_Gen) + i] = date[i]\;
  return reinterpret_cast<const char*>(&result_gen[0])\;
}
  ]==]
  )

  file(CONFIGURE
    OUTPUT ${output_dir}/${target_name}_gen_version.h_tmp
    CONTENT ${filedata_to_write_static_h}
  )

  file(CONFIGURE
    OUTPUT ${output_dir}/${target_name}_gen_version.cpp_tmp
    CONTENT ${filedata_to_write_static_cpp}
  )

  Compare2Files(${output_dir}/${target_name}_gen_version.cpp_tmp ${output_dir}/${target_name}_gen_version.cpp)
  if(Compare2FilesRet)
    file(REMOVE ${output_dir}/${target_name}_gen_version.cpp)
    file(CONFIGURE
      OUTPUT ${output_dir}/${target_name}_gen_version.cpp
      CONTENT ${filedata_to_write_static_cpp}
    )
#    file(COPY_FILE ${output_dir}/${target_name}_gen_version.cpp_tmp ${output_dir}/${target_name}_gen_version.cpp)
  endif()


  set (version_sources
    ${output_dir}/${target_name}_gen_version.h
    ${output_dir}/${target_name}_gen_version.cpp
  )

  target_include_directories(${target_name} PRIVATE ${output_dir})
  target_sources(${target_name} PRIVATE ${version_sources})
  source_group("Version Generated" FILES ${version_sources})

endfunction()

function(EnsureVersionInformation TARGET_NAME REPOSITORY_DIR IS_PUBLIC)
  ReadVersionFromFile("${CMAKE_SOURCE_DIR}/VERSION" Version)
  AcquireGitlabPipelineBranchId(PipelineBranchId)
  AcquireProjectId(ProjectId)
  AcquireRefName(RefName)
  AcquireGitlabPipelineId(PipelineId)
  AcquireGitInformation("${REPOSITORY_DIR}" GitInfo)

  string(REGEX REPLACE "AAA(.+)BBB.+CCC.+DDD.+EEE" "\\1" CommitterDate ${GitInfo})
  string(REGEX REPLACE "AAA.+BBB(.+)CCC.+DDD.+EEE" "\\1" AbbreviatedHash ${GitInfo})
  string(REGEX REPLACE "AAA.+BBB.+CCC(.+)DDD.+EEE" "\\1" AuthorName ${GitInfo})
  string(REGEX REPLACE "AAA.+BBB.+CCC.+DDD(.+)EEE" "\\1" Subject ${GitInfo})

  string(REPLACE "\n" "" PipelineBranchId ${PipelineBranchId})
  string(REPLACE "\n" "" ProjectId ${ProjectId})
  string(REPLACE "\n" "" RefName ${RefName})
  string(REPLACE "\n" "" PipelineId ${PipelineId})
  string(REPLACE "\n" "" CommitterDate ${CommitterDate})
  string(REPLACE "\n" "" AbbreviatedHash ${AbbreviatedHash})
  string(REPLACE "\n" "" AuthorName ${AuthorName})
  string(REPLACE "\n" "" Subject ${Subject})
  string(REPLACE "\n" "" Version ${Version})

  if(ENABLE_TEST_BUILD)
    set(Version "${Version} - this is test build")
  endif()

  set(VERSION_GEN_OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/versiongen)

  string(REPLACE "\n" "" PipelineBranchId ${PipelineBranchId})
  string(REPLACE "\n" "" ProjectId ${ProjectId})
  string(REPLACE "\n" "" RefName ${RefName})
  string(REPLACE "\n" "" PipelineId ${PipelineId})
  string(REPLACE "\n" "" CommitterDate ${CommitterDate})
  string(REPLACE "\n" "" AbbreviatedHash ${AbbreviatedHash})
  string(REPLACE "\n" "" AuthorName ${AuthorName})
  string(REPLACE "\n" "" Subject ${Subject})
  string(REPLACE "\n" "" Version ${Version})

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
    git commit hash: AbbreviatedHash
    git commit timestamp: CommitterDate
    git commit author: AuthorName
    git subject: Subject
    project path: [RefName]ProjectId
    build pipeline: PipelineBranchId.PipelineId
    product version: PipelinVersioneBranchId
    build date: ]==]
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

  FileWriteIsChanged(${VERSION_GEN_OUT_DIR}/${TARGET_NAME}_version_gen.xml ${XML_CONTEXT})
  FileWriteIsChanged(${VERSION_GEN_OUT_DIR}/${TARGET_NAME}_gitlab_gen.txt ${GEN_CONTEXT})

  create_source_version_files(${TARGET_NAME} ${VERSION_GEN_OUT_DIR} ${TARGET_NAME}_version_gen.xml ${TARGET_NAME}_gitlab_gen.txt)

endfunction()
