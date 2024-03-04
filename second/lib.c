#include <stdio.h>
#include "lib.h"
#include <version_git_example2_gen_C.h>

int lib_c()
{
  printf("a=%s\n", version_git_example2_TEXT_RESOURCE_TXT());
  return 0;
}
