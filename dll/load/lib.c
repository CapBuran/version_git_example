#include <stdio.h>
#include "lib.h"
#include <../gen/load_dll_gen_C.h>

int lib_c()
{
  printf("a=%s\n", no_load_dll_TEXT_RESOURCE_TXT());
  return 0;
}
