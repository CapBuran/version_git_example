#include "lib.h"
#include <version_git_example2_versiongen_CPP.h>

#include <iostream>

int lib()
{
  std::cout << "New Line1" << std::endl;
  std::cout << version_git_example2_gitlab_gen_txt() << std::endl;
  std::cout << "New Line2" << std::endl;
  lib_c();
  std::cout << "New Line3" << std::endl;
  return 0;
}
