#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

char *const kdv_client[] = {"Karabiner-DriverKit-VirtualHIDDeviceClient"};

int main(int argc, char *argv[]) {
  if (argc < 2) {
    perror("karabiner-daemon-shim: missing program to call");
    return 1;
  }
  int r = fork();
  if (r < 0) {
    perror("karabiner-daemon-shim: fork");
    return 1;
  } else if (r == 0) {
    r = execvp(kdv_client[0], kdv_client);
  } else {
    // To give time for kdv-client to start
    sleep(1);
    r = execvp(argv[1], &argv[1]);
  };
  if (r < 0) {
    perror("karabiner-daemon-shim: execvp");
    return 1;
  }
}
