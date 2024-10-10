.text

#        ENTRY                  /*  mark the first instruction to call */
.global start
.global sudoku_candidatos_propagar_arm

@ Recorre la cuadricula y llama a las funciones de propagacion si la celda tiene un valor distinto a 0
sudoku_candidatos_propagar_arm:
	@ r0 = cuadricula
	@ r1 = indice fila
	@ r2 = indice columna
	@ r3 = valor actual celda
	@ r6 = bit desplazado (se usara para desactivar los candidatos)

	push {r0, r5, lr}

	loop_i:
		cmp r1, #9
		bge loop_i_end					@ Comprobar si se ha llegado a la ultima fila

		lsl r4, r1, #5					@ Desplazamiento a siguiente fila (r1 * 32)

		mov r2, #0
	loop_j:
		cmp r2, #9
		bge loop_j_end					@ Comprobar si se ha llegado a la ultima columna

		lsl r5, r2, #1					@ Desplazamiento a siguiente columna (r2 * 2)

		add r7, r4, r5					@ Desplazamiento total (fila + columna)
		ldrh r3, [r0, r7]


		and r3, r3, #0xF				@ Objeter valor actual de la celda (celda_leer_valor)

		cmp r3, #0						@ Compara si hay un valor en la celda (si == 0, se omite la propagacion)
		beq skip_propagation
		push {r1, r2, lr}			@ Backup de indices y valor de la celda

		add r8, r3, #3					@ r4 = displace = (3 + r3)
		mov r6, #1
		lsl r6, r6, r8					@ desplazar bit a la izquierda r4 posiciones

@ ---------------------------- Actualizar candidatos de las filas (verticalmente) ----------------------------
		bl update_row_candidates
@ ---------------------------- Actualizar candidatos de las columnas (horizontalmente) ----------------------------
		bl update_column_candidates

		pop {r1, r2, lr}			@ Restaurar valor de los indices y la celda
		skip_propagation:
			add r2, r2, #1
			b loop_j
	loop_j_end:
		add r1, r1, #1
		b loop_i
	loop_i_end:
		pop {r0, r5, lr}				@ Restaurar valor de la cuadricula y el programa
		bx lr

@ ---------------------------- Calculo de los indices para la seccion correspondiente ----------------------------
	@bl update_region_candidates

update_row_candidates:
    mov r1, #0                   @ Inicializar el contador de fila en 0
fila_loop:
    cmp r1, #9                   @ Comparar si se ha llegado a la última fila (9)
    bge fin_fila                 @ Si es mayor o igual a 9, salir del bucle

    lsl r2, r1, #5               @ Desplazamiento de la fila (r1 * 32)
    add r8, r2, r5               @ r4 = desplazamiento fila + columna (columna es fija en r5)

    ldrh r3, [r0, r8]            @ Cargar el valor de la celda de la fila actual

    bic r3, r3, r6               @ celda &= ~(1 << displace) - Actualizar los bits candidatos
    strh r3, [r0, r8]            @ Guardar el valor actualizado en la celda

    add r1, r1, #1               @ Siguiente fila
    b fila_loop                  @ Repetir para la siguiente fila

fin_fila:
    bx lr

update_column_candidates:
    mov r1, #0                   @ Inicializar el contador de columna en 0
col_loop:
    cmp r1, #9                   @ Comparar si se ha llegado a la última columna (9)
    bge fin_col                  @ Si es mayor o igual a 9, salir del bucle

    lsl r2, r1, #1               @ Desplazar la columna (r1 * 2) para acceder a la celda correcta
    add r8, r4, r2               @ r5 = desplazamiento fila + desplazamiento columna

    ldrh r3, [r0, r8]            @ Cargar el valor de la celda en la columna y fila actuales

    bic r3, r3, r6               @ celda &= ~(1 << displace) - Actualizar los bits candidatos
    strh r3, [r0, r8]            @ Guardar el valor actualizado en la celda

    add r1, r1, #1               @ Incrementar el contador de columna
    b col_loop                   @ Repetir para la siguiente columna

fin_col:
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
