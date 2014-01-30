CC=gcc
LFLAGS=-lm -lOpenCL
CFLAGS=-std=c99 -Wall -c

all: main

main:	main.o
	$(CC) $^ $(LFLAGS) -o $@

main.o:
	$(CC) $(CFLAGS) main.c

clean:
	rm main.o
