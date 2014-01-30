CC=gcc
LFLAGS=-lm -lOpenCL
CFLAGS=-std=c99 -Wall -c

all: main

main:	main.o
	$(CC) main.o $(LFLAGS) -o main

main.o:
	$(CC) $(CFLAGS) main.c

clean:
	rm main
