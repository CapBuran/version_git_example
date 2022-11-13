@echo off
set current=%CD%
set ConfigBuild=Debug
set PATH=F:\Repositories\cmake\out\build\x64-Debug\bin;%PATH%

if not exist %current%\build md %current%\build

set CMAKE_EXE=cmake -A x64
set CMAKE_CMD=%CMAKE_EXE% ..

echo %CMAKE_CMD%

rem cmake.exe --version

rem pause

pushd %current%\build
%CMAKE_CMD% 2>&1
popd
