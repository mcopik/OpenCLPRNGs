CC=gcc
LFLAGS=-lm -lOpenCL
CFLAGS=-std=c99 -Wall -g -c
OBJECTS=main.o
all: main

main:	$(OBJECTS)
	$(CC) $^ $(LFLAGS) -o $@

%.o: %.c
	$(CC) $< $(CFLAGS) -o $@

clean:
	rm main.o
