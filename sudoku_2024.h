/* guarda para evitar inclusiones multiples ("include guard") */
#ifndef SUDOKU_H_2024
#define SUDOKU_H_2024

#include <inttypes.h>

/* Tamanyos de la cuadrícula */
/* Se utilizan 16 columnas para facilitar la visualización */
enum {NUM_FILAS = 9, NUM_COLUMNAS = 16};

/* Definiciones para valores muy utilizados */
enum {FALSE = 0, TRUE = 1};

typedef uint16_t CELDA;
/* La información de cada celda esta codificada en 16 bits
 * con el siguiente formato, empezando en el bit mas significativo (MSB):
 * 1 bit  PISTA
 * 1 bit  ERROR
 * 1 bit  no usado
 * 9 bits vector CANDIDATOS
 * 4 bits VALOR
 */


/* declaración de funciones visibles en el exterior */
void sudoku9x9(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS], char *ready);

/* declaración de funciones ARM/thumb a implementar */
int
sudoku_candidatos_init_arm(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS]);

int
sudoku_candidatos_propagar_arm(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS],
                               uint8_t fila, uint8_t columna, uint8_t valor);

int
sudoku_candidatos_propagar_thumb(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS],
                                 uint8_t fila, uint8_t columna);


#endif /* SUDOKU_H_2024 */
