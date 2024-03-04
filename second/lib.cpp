#include "lib.h"
#include <version_git_example2_versiongen_CPP.h>

#include <iostream>

extern "C"
{
  int lib_c();
}

int lib()
{
  std::cout << "New Line" << std::endl;
  std::cout << version_git_example2_gitlab_gen_txt() << std::endl;
  std::cout << "New Line" << std::endl;
  std::cout << lib_c() << std::endl;
  std::cout << "New Line" << std::endl;
  return 0;
}
