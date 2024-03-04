#include <version_git_example1_versiongen_CPP.h>

#include <iostream>

extern "C"
{
  int main_c();
}

int main()
{
  std::cout << "New Line" << std::endl;
  std::cout << version_git_example1_gitlab_gen_txt() << std::endl;
  std::cout << "New Line" << std::endl;
  main_c();
  std::cout << "New Line" << std::endl;
  return 0;
}
