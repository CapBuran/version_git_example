#include "lib.h"
#include <../gen/load_dll_gen_CPP.h>
#include <load_dll_versiongen_CPP.h>

#include <iostream>

int lib()
{
  std::cout << "New Line1" << std::endl;
  std::cout << load_dll_gitlab_gen_txt() << std::endl;
  std::cout << "New Line2" << std::endl;
  lib_c();
  std::cout << "New Line3" << std::endl;
  return 0;
}
