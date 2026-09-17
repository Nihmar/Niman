#include "my_application.h"

#include <unistd.h>

#include <cstdio>

int main(int argc, char** argv) {
  int exit_status;
  {
    g_autoptr(MyApplication) app = my_application_new();
    exit_status = g_application_run(G_APPLICATION(app), argc, argv);
  }

  // Leave without running the libc exit handlers (issue #108). On NVIDIA
  // one of them tears EGL down and segfaults doing it, so every close
  // ended in SIGSEGV and a core dump. By here the window is gone, the
  // Flutter engine is shut down and the notes are on disk: those
  // handlers have nothing of ours left to run, only the driver's own
  // teardown, which the kernel does for us anyway.
  std::fflush(nullptr);
  _exit(exit_status);
}
