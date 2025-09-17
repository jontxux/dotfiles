# ==========================
#    Makefile para barra_i3
# ==========================

# Compilador
CC      := gcc

# Flags de compilación
CFLAGS  := -Wall -Wextra -O2

# Librerías
LDFLAGS := -lpulse -ljson-c -lpthread

# Nombre del ejecutable
TARGET  := barra

# Archivos fuente y objeto
SRC     := barra.c
OBJ     := $(SRC:.c=.o)

# Colores (con printf funcionan siempre)
GREEN   := \033[0;32m
BLUE    := \033[0;34m
YELLOW  := \033[1;33m
RESET   := \033[0m

# ==========================
#    Reglas
# ==========================

all: $(TARGET)

$(TARGET): $(OBJ)
	@printf "$(BLUE)[LINK]$(RESET) %s\n" $@
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	rm -f $(OBJ)   # <<< Borra los .o después de compilar
	@printf "$(GREEN)[OK]$(RESET) Compilación completada.\n"

%.o: %.c
	@printf "$(YELLOW)[CC]$(RESET) %s\n" $<
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@printf "$(BLUE)[CLEAN]$(RESET)\n"
	rm -f $(OBJ) $(TARGET)

rebuild: clean all

install: $(TARGET)
	@printf "$(BLUE)[INSTALL]$(RESET) Copiando a /usr/local/bin\n"
	cp $(TARGET) /usr/local/bin/

uninstall:
	@printf "$(BLUE)[UNINSTALL]$(RESET) Borrando de /usr/local/bin\n"
	rm -f /usr/local/bin/$(TARGET)

info:
	@echo "Compilador: $(CC)"
	@echo "Flags de compilación: $(CFLAGS)"
	@echo "Librerías: $(LDFLAGS)"
	@echo "Objetivo: $(TARGET)"

.PHONY: all clean rebuild install uninstall info
