#if !defined(__riscv) || __riscv_xlen != 64
#error "This code is only supported on RISC-V 64-bit platforms."
#endif

#define DISABLE_TIME_INTR 0x100
#define NOTIFY_PROFILER 0x101
#define NOTIFY_PROFILE_EXIT 0x102
#define GOOD_TRAP 0x0
void nemu_signal(int a){
asm volatile ("mv a0, %0\n\t"
              ".insn r 0x6B, 0, 0, x0, x0, x0\n\t"
              :
              : "r"(a)
              : "a0");
}

#include <time.h>
#include <stdio.h>

void sleep_nanoseconds(long nanoseconds) {
  printf("%ldns\n", nanoseconds);
  struct timespec req, rem;
  req.tv_sec = 0;
  req.tv_nsec = nanoseconds;

  if (my_syscall2(__NR_nanosleep, &req, &rem) == -1) {
      my_syscall2(__NR_nanosleep, &rem, NULL);
  }
}

int main() {
  nemu_signal(NOTIFY_PROFILER);
  sleep_nanoseconds(1234L);
  sleep_nanoseconds(2134L);
  sleep_nanoseconds(1234L);
  nemu_signal(GOOD_TRAP);
  return 0;
}
