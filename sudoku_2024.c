#include "sudoku_2024.h"
#include <stdio.h>
#include <stdlib.h>

//extern void
//sudoku_candidatos_propagar_arm(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS], uint8_t fila, uint8_t columna, uint8_t valor);
/* *****************************************************************************
 * Funciones privadas (static)
 * (no pueden ser invocadas desde otro fichero) */
 
/* *****************************************************************************
 * modifica el valor almacenado en la celda indicada */
static inline void
celda_poner_valor(CELDA *celdaptr, uint8_t val)
{
    *celdaptr = (*celdaptr & 0xFFF0) | (val & 0x000F);
}

/* *****************************************************************************
 * extrae el valor almacenado en los 16 bits de una celda */
static inline uint8_t
celda_leer_valor(CELDA celda)
{
    return (celda & 0x000F);
}

static inline void
activar_error(CELDA celda)
{
	celda = celda |= 0x4000;
}

/* *****************************************************************************
 * propaga el valor de una determinada celda
 * para actualizar las listas de candidatos
 * de las celdas en su su fila, columna y region */
void
sudoku_candidatos_propagar_c(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS], int fila, int columna, uint8_t valor)
{
	int displace = 3 + (int)valor;

    /* recorrer fila descartando el valor en la lista de candidatos */
    int col = 0;
    while(col < NUM_COLUMNAS - 7){
    	cuadricula[fila][col] &= ~(1 << displace);
    	col++;
    }

    /* recorrer columna descartando el valor en la lista de candidatos */
    int row = 0;
    while(row < NUM_FILAS){
    	cuadricula[row][columna] &= ~(1 << displace);
    	row++;
    }


    /*Calcular la posicion inicial para la region correspondiente*/
    int row_start = (fila / 3) * 3;
    int col_start = (columna / 3) * 3;

    /* recorrer region descartando el valor en la lista de candidatos */
    row = row_start;
    while(row < (row_start + 3)){
    	int col = col_start;
    	while(col < (col_start + 3)){
    		cuadricula[row][col] &= ~(1 << displace);
    		col++;
    	}
    	row++;
    }
}

void
init_candidatos(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS]){
	int row=0;
	while(row < NUM_FILAS){
		int col=0;
		while(col < NUM_COLUMNAS - 7){

			uint8_t valor_actual = celda_leer_valor(cuadricula[row][col]);

			if(valor_actual == 0){
				cuadricula[row][col] |= 0x1FF0;
			}
			col++;
		}
		row++;
	}
}

void
propagar_if_value(CELDA *cuadricula[NUM_FILAS][NUM_COLUMNAS], int *celdas_vacias){
	int row=0;
	while(row < NUM_FILAS){
		int col=0;
		while(col < NUM_COLUMNAS - 7){
			uint8_t celda_actual = cuadricula[row][col];
			uint8_t valor_actual = celda_leer_valor(celda_actual);
			if(valor_actual == 0x0000){
				(*celdas_vacias)++;
			} else {
				sudoku_candidatos_propagar_arm(&cuadricula, row, col, valor_actual);
				//sudoku_candidatos_propagar_c(cuadricula,row,col,valor_actual);
			}
			col++;
		}
		row++;
	}
}

/* *****************************************************************************
 * calcula todas las listas de candidatos (9x9)
 * necesario tras borrar o cambiar un valor (listas corrompidas)
 * retorna el numero de celdas vacias */
static int
sudoku_candidatos_init_c(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS])
{
 	int celdas_vacias = 0;
	/*TODO: inicializa lista de candidatos */
    init_candidatos(cuadricula);

    /* TODO: propagar si la celda tiene valor*/
    propagar_if_value(cuadricula, &celdas_vacias);

    return celdas_vacias;
}


static void
cuadricula_candidatos_verificar(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS],int row, int col, int *errors){

	uint8_t valor = celda_leer_valor(cuadricula[row][col]);

	if(valor != 0x0000){
		int displace = 3 + (int)valor;

		//Verificar el valor en toda la fila (Horizontal)
		int j = 0;
		while( j < NUM_COLUMNAS - 7){
			uint8_t is_bit_set = cuadricula[row][j] & (1 << displace);

			if(j != col && is_bit_set){
				activar_error(cuadricula[row][j]);
				(*errors)++;
			}
			j++;
		}

		//Verificar el valor en toda la columna (Vertical)
		int i = 0;
		while(i < NUM_FILAS){
			uint8_t is_bit_set = cuadricula[i][col] & (1 << displace);
			if(i != row && is_bit_set){
				activar_error(cuadricula[i][col]);
				(*errors)++;
			}
			i++;
		}

		/*Calcular la posicion inicial para seccion correspondiente a la ubicacion actual*/
		int row_start = (row / 3) * 3;
		int col_start = (col / 3) * 3;

		//Verificar valor en la seccion (cuadro 3x3)
		i = row_start;
		while(i < (row_start + 3)){
			int j = col_start;
			while(j < (col_start + 3)){
				uint8_t is_bit_set = cuadricula[i][j] & (1 << displace);
				if((i != row_start || j != col_start) && is_bit_set){
					activar_error(cuadricula[i][j]);
					(*errors)++;
				}
				j++;
			}
			i++;
		}
	}
}
/* *****************************************************************************
 * Funciones publicas
 * (pueden ser invocadas desde otro fichero) */

/* *******************************************cuadricula[NUM_FILAS][NUM_COLUMNAS]**********************************
 * programa principal del juego que recibe el tablero,
 * y la senyal de ready que indica que se han actualizado fila y columna */
void
sudoku9x9(CELDA cuadricula[NUM_FILAS][NUM_COLUMNAS], char *ready)
{
    int celdas_vacias;

    /* calcula lista de candidatos, versi—n C */
    celdas_vacias = sudoku_candidatos_init_c(cuadricula);

    /* verificar que la lista de candidatos calculada es correcta */
    int errors = 0;
    int row = 0;
    while(row < NUM_FILAS){
		int col = 0;
    	while(col < NUM_COLUMNAS - 7){
    		cuadricula_candidatos_verificar(cuadricula, row, col, &errors);
    		col++;
    	}
    	row++;
    }
    /* repetir para otras versiones (C optimizado, ARM, THUMB) */
}

