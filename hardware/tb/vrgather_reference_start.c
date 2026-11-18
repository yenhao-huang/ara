// SPDX-License-Identifier: SHL-0.51
// Linux-user runner for TEST_CASE7; no privileged mstatus access.
// Link with vrgather.c compiled using -Dmain=ara_test_main and section GC.
extern void TEST_CASE7(void);
extern int num_failed;
static int checks;
int printf_(const char *format, ...) {
  if (format[0] == 'P') checks++;
  return 0;
}
void *memcpy(void *dst, const void *src, unsigned long n) {
  unsigned char *d = dst;
  const unsigned char *s = src;
  for (unsigned long i = 0; i < n; i++) d[i] = s[i];
  return dst;
}
static long syscall3(long nr, long a0, long a1, long a2) {
  register long x10 asm("a0") = a0;
  register long x11 asm("a1") = a1;
  register long x12 asm("a2") = a2;
  register long x17 asm("a7") = nr;
  asm volatile("ecall" : "+r"(x10) : "r"(x11), "r"(x12), "r"(x17) : "memory");
  return x10;
}
void _start(void) {
  TEST_CASE7();
  int failed = num_failed || checks != 8;
  static const char pass[] = "PASS: TEST_CASE7 (8 comparisons)\n";
  static const char fail[] = "FAIL: TEST_CASE7\n";
  syscall3(64, 1, (long)(failed ? fail : pass), failed ? sizeof(fail)-1 : sizeof(pass)-1);
  syscall3(93, failed, 0, 0);
  __builtin_unreachable();
}
