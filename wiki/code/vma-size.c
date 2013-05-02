#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define MEGABYTES 1024 * 1024

int main(int argc, char *argv[])
{
	size_t mem_size = 4 * MEGABYTES;
	pid_t pid = getpid();
	char *mem = (char *)malloc(mem_size);
	/* memset(mem, 0, mem_size / 2); */
	printf("%d mem region: %x-%x\n", (int)pid, (long int)mem, (long int)mem + mem_size);
	sleep(3600);
	return 0;
}
