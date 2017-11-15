CC = mpicc
CFLAGS = -g -std=gnu99
INCLUDES = -I/home/brandon/Documents/crest/nbody/inc $(shell pkg-config --cflags hpx)
LIBS = $(shell pkg-config --static --libs hpx)


SRC = $(shell ls *.c)
OBJ = $(SRC:.c=.o)
TARGET = nbody

.PHONY: clean help

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o $(TARGET) $(OBJ) $(LIBS)

%.o:%.c
	$(CC) $(CFLAGS) -c $< -o $@ $(INCLUDES)

clean:
	rm -f $(OBJ) $(TARGET) *~


