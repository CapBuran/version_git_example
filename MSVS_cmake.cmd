@echo off
set current=%CD%
SET ConfigBuild=Debug

if not exist %current%\build md %current%\build

SET CMAKE_EXE=cmake -A x64
SET CMAKE_CMD=%CMAKE_EXE%

PUSHD %current%\build
%CMAKE_CMD% .. 2>&1
POPD
