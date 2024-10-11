.text

#        ENTRY                  /*  mark the first instruction to call */
.global start
.global sudoku_candidatos_propagar_arm

@ Recorre la cuadricula llamando a las funciones de propagacion (fila, columna y region) SI la celda tiene un valor distinto a 0
sudoku_candidatos_propagar_arm:

	@ r0 = cuadricula
	@ r1 = indice fila
	@ r2 = indice columna
	@ r3 = valor actual celda
	@ r4 = desplazamiento de la fila
	@ r5 = desplazamiento de la columna
	@ r6 = bit desplazado (se usara para desactivar los candidatos)
	@ r7 = desplazamiento total (r4 + r5)

loop_i:
	cmp r1, #9
	bge loop_i_end

	lsl r4, r1, #5						@ Desplazamiento a siguiente fila (r1 * 32 bytes)

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

	add r8, r3, #3					@ r8 = displace = (3 + r3)
	mov r6, #1
	lsl r6, r6, r8					@ desplazar bit a la izquierda r4 posiciones

	bl update_row_candidates

	bl update_column_candidates

	push {r1, r2, lr}
	bl calc_region_indexes
	bl update_region_candidates
	pop {r1, r2, lr}

skip_propagation:
	add r2, r2, #1
	b loop_j
loop_j_end:
	add r1, r1, #1
	b loop_i
loop_i_end:
	pop {r0, r5, lr}					@ Restaurar valor de la cuadricula y el programa sudoku9x9
	B stop


update_row_candidates:
    mov r8, #0
fila_loop:
    cmp r8, #9
    bge fin_fila

    lsl r9, r8, #5               		@ Desplazar la fila (r1 * 32)
    add r10, r9, r5               		@ r10 = desplazamiento total = fila + columna (columna fija para r5)

    ldrh r3, [r0, r10]

    bic r3, r3, r6               		@ celda &= ~(1 << displace) - Actualizar el bit candidato
    strh r3, [r0, r10]

    add r8, r8, #1
    b fila_loop

fin_fila:
    bx lr

update_column_candidates:
    mov r8, #0
col_loop:
    cmp r8, #9
    bge fin_col

    lsl r9, r8, #1               		@ Desplazar la columna (r1 * 2)
    add r10, r4, r9               		@ r8 = desplazamiento total = fila + columna (fila fija para r4)

    ldrh r3, [r0, r10]

    bic r3, r3, r6               		@ celda &= ~(1 << displace) - Actualizar bit candidato
    strh r3, [r0, r10]

    add r8, r8, #1
    b col_loop

fin_col:
    bx lr


calc_region_indexes:
	mov r8, r2
	mov r9, #0
col_index:
	cmp r8, #3
	blt col_index_end					@ Si es menor a 3, termina el calculo de columna

	sub r8, r8, #3
	add r9, r9, #3
	b col_index
col_index_end:
	mov r2, r9							@ Guardar el indice calculado en r1 (fila)

	mov r8, r1
	mov r9, #0
row_index:
	cmp r8, #3
	blt row_index_end					@ Si es menor a 3, termina el calculo de fila

	sub r8, r8, #3
	add r9, r9, #3
	b row_index
row_index_end:
	mov r1, r9							@ Guardar el indice calculado en r2 (columna)

	add r8, r1, #3						@ Limite superior de la fila
	add r9, r2, #3						@ Limite superior de la columna

	bx lr

update_region_candidates:
	@ r0 = cuadricula
	@ r1 = indice inicial region (fila)
	@ r2 = indice inicial region (columna)
	@ r3 = valor_celda
	@ r4 = limite max region (fila)
	@ r5 = limite max region (columna)
	@ r6 = bit e desactivacion desplazado

region_row_loop:
	cmp r1, r8
	bge end_of_region

region_col_loop:
	cmp r2, r9
	bge end_of_column

	lsl r10, r1, #5						@ Desplazamiento fila (r1 * 32)
	lsl r11, r2, #1						@ Desplazamiento columna (r2 * 2)
	add r12, r10, r11					@ Desplazamiento total de la celda (fila + columna)

	ldrh r3, [r0, r12]
	bic r3, r3, r6						@ celda &= ~(1 << displace)
	strh r3, [r0, r12]
	add r2, r2, #1
	b region_col_loop

end_of_column:
	add r1, r1, #1
	sub r2, r2, #3
	b region_row_loop

end_of_region:
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
