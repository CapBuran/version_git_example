#include "lib.h"
#include <version_git_example2_resource.h>

#include <iostream>

int lib()
{
  std::cout << "New Line" << std::endl;
  std::cout << version_git_example2_gitlab_gen_txt() << std::endl;
  std::cout << "New Line" << std::endl;
  return 0;
}
