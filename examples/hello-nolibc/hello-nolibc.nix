{ runCommand
, runCommandCC
, linux
}: let
  nolibc = runCommand "nolibc" {} ''
    path=$(tar tf ${linux.src} | grep tools/include/nolibc | sort | head -n1)
    tar xf ${linux.src}
    mv $path $out
  '';
  hello-src = builtins.toFile "hello.c" ''
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
    #include <stdio.h>
    int main() {
      nemu_signal(NOTIFY_PROFILER);
      printf("Hello, World!\n");
      nemu_signal(GOOD_TRAP);
      return 0;
    }
  '';
  hello-nolibc = runCommandCC "hello-nolibc" {} ''
    mkdir -p $out/bin
    $CC -nostdlib -I ${nolibc} ${hello-src} -o $out/bin/hello
  '';
in hello-nolibc
