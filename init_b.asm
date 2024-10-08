.text

#        ENTRY                  /*  mark the first instruction to call */
.global start
.global sudoku_candidatos_propagar_arm

sudoku_candidatos_propagar_arm:
	@ r0 = cuadricula
	@ r1 = fila
	@ r2 = columna
	@ r3 = valor celda
	push {r0, lr}

	mov r4, #0
    add r4, r3, #3				@ r4 = displace = (3 + valor)

	mov r6, #1					@ r6 bit de desactivacion
    lsl r6, r6, r4				@ desplazar bit a la izquierda r4 posiciones

@ ---------------------------- Actualizar candidatos de las columnas (horizontalmente) ----------------------------
	bl update_column_candidates
@ ---------------------------- Actualizar candidatos de las filas (verticalmente) ----------------------------
	bl update_row_candidates
@ ---------------------------- Calculo de los indices para la seccion correspondiente ----------------------------
	bl update_region_candidates

	pop {r0, lr}
	bx lr


update_column_candidates:
	mov r7, #0
col_loop:
    cmp r7, #9					@ Comparar si se ha llegado a la ultima columna (9)
    bge fin_col

	lsl r8, r7, #1				@ r8 = desplazamiento a siguiente celda

	ldrh r9, [r0, r8]

    bic r9, r9, r6           	@ celda &= ~(1 << displace)
    strh r9, [r0, r8]

    add r7, r7, #1
    b col_loop

fin_col:
	bx lr


update_row_candidates:
	mov r7, #0					@ reinicar contador
fila_loop:
    cmp r7, #9                 @ Comparar si se ha llegado a la ultima fila (9)
    bge fin_fila

	lsl r8, r7, #5				@ r8 = desplazamiento a siguiente celda

	ldrh r9, [r0, r8]

    bic r9, r9, r6           	@ celda &= ~(1 << displace)
    strh r9, [r0, r8]

    add r7, r7, #1
    b fila_loop

fin_fila:
	bx lr


update_region_candidates:
	mov r7, #0
col_index:
	cmp r2, #3					@ Compara que el dividendo sea mayor que el divisor
	blt col_index_end

	sub r2, r2, #3
	add r7, r7, #1
	b col_index

col_index_end:					@ El indice de la seccion por columna queda guardado en r7

	mov r8, #0
row_index:
	cmp r1, #3					@ Compara que el dividendo sea mayor que el divisor
	blt row_index_end

	sub r1, r1, #3
	add r8, r8, #1
	b row_index

row_index_end:					@ El indice de la seccion por fila queda guardado en r8

@ ---------------------------- Recorrer cada fila y actualizar candidatos de la seccion ----------------------------
	mov r1, r8					@ Mover el indice r8 a r1 (fila)
	mov r2, r7					@ Mover el indice r7 a r2 (columna)

	mov r7, #0					@ Contador de la fila (Verticalmente)
row_loop:
	cmp r7, #3
	bge row_end

	add r8, r1, r7
	lsl r8, r8, #5				@ Desplazamiento hacia la siguiente fila r8

	mov r9, #0					@ Contador de la columna (horizontalmente)
	column_loop:
		cmp r9, #3
		bge column_end

		add r10, r2, r9
		lsl r10, r10, #1		@ Desplazamiento a la siguiente columna r10

		add r11, r8, r10
		ldrh r12, [r0, r11]		@ Cargar la celda en el registro 12

		bic r12, r12, r6		@ celda &= ~(1 << displace)
		strh r12, [r0, r11]		@ Guardar el nuevo valor en la celda

		add r9, r9, #1
		b column_loop

	column_end:
		add r7, r7, #1
		b row_loop
row_end:
	bx lr

start:
.arm    /* indicates that we are using the ARM instruction set */

#------standard initial code
# --- Setup interrupt / exception vectors
      B       Reset_Handler
/* In this version we do not use the following handlers */
################################################################################
#-----------Undefined_Handler:
#      B       Undefined_Handler
#----------SWI_Handler:
#      B       SWI_Handler
#----------Prefetch_Handler:
#      B       Prefetch_Handler
#----------Abort_Handler:
#      B       Abort_Handler
#         NOP      /* Reserved vector */
#----------IRQ_Handler:
#      B       IRQ_Handler
#----------FIQ_Handler:
#      B       FIQ_Handler

################################################################################
# Reset Handler:
# the processor starts executing this code after system reset
################################################################################
Reset_Handler:
#
        MOV     sp, #0x4000      /*  set up stack pointer (r13) */
#
#  USING A .C FUNCTION
#
# FUNCTION CALL the parameters are stored in r0 and r1
# If there are 4 or less parameters when calling a C function the compiler
# assumes that they have been stored in r0-r3.
# If there are more parameters you have to store them in the data stack
# using the stack pointer
# function __c_copy is in copy.c
        LDR     r0, =cuadricula  /*  puntero a la @ inicial de la cuadricula */

.extern     sudoku9x9
        ldr         r5, = sudoku9x9
        mov         lr, pc
        bx          r5

stop:
        B       stop        /*  end of program */

################################################################################
.data
.ltorg     
.align 5    /* guarantees 32-byte alignment (2^5) */

# huecos para cuadrar
cuadricula:
     /* 9 filas de 16 entradas para facilitar la visualizacion, 16 bits por celda */
    .hword   0x8005,0x0000,0x0000,0x8003,0x0000,0x0000,0x0000,0x0000,0x0000,0, 0,0,0,0,0,0
    .hword   0x0000,0x0000,0x0000,0x0000,0x8009,0x0000,0x0000,0x0000,0x8005,0,0,0,0,0,0,0
    .hword   0x0000,0x8009,0x8006,0x8007,0x0000,0x8005,0x0000,0x8003,0x0000,0,0,0,0,0,0,0
    .hword   0x0000,0x8008,0x0000,0x8009,0x0000,0x0000,0x8006,0x0000,0x0000,0,0,0,0,0,0,0
    .hword   0x0000,0x0000,0x8005,0x8008,0x8006,0x8001,0x8004,0x0000,0x0000,0,0,0,0,0,0,0
    .hword   0x0000,0x0000,0x8004,0x8002,0x0000,0x8003,0x0000,0x8007,0x0000,0,0,0,0,0,0,0
    .hword   0x0000,0x8007,0x0000,0x8005,0x0000,0x8009,0x8002,0x8006,0x0000,0,0,0,0,0,0,0
    .hword   0x8006,0x0000,0x0000,0x0000,0x8008,0x0000,0x0000,0x0000,0x0000,0,0,0,0,0,0,0
    .hword   0x0000,0x0000,0x0000,0x0000,0x0000,0x8002,0x0000,0x0000,0x8001,0,0,0,0,0,0,0

.end
#        END
