CC = gcc
CFLAGS = -g
LDFLAGS =


poly: poly.o dump.o
	$(CC) $(LDFLAGS) -o poly poly.o dump.o
poly.o: poly.c
	$(CC) $(CFLAGS) -c poly.c
dump.o: dump.c
	$(CC) $(CFLAGS) -c dump.c