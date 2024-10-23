.text

#        ENTRY                  /*  mark the first instruction to call */
.global start
.global sudoku_candidatos_propagar_arm
.global sudoku_candidatos_init_arm
.global sudoku_candidatos_propagar_thumb

################################################################################
.thumb

sudoku_candidatos_propagar_thumb:
    @ r0 = cuadricula
    @ r1 = indice fila
    @ r2 = indice columna
    @ r3 = valor actual celda
    @ r4 = desplazamiento de la fila
    @ r5 = desplazamiento de la columna
    @ r6 = bit desplazado (se usara para desactivar los candidatos)
    @ r7 = desplazamiento total (r4 + r5)

    movs r6, #0							@ Inicializar contador de celdas vacías a 0

thumb_loop_i:
    cmp r1, #9
    bge thumb_loop_i_end

    lsl r4, r1, #5						@ Desplazamiento a siguiente fila (r1 * 32 bytes)

    mov r3, #0
thumb_loop_j:
    cmp r2, #9
    bge thumb_loop_j_end

    lsl r5, r2, #1						@ Desplazamiento a siguiente columna (r2 * 2 bytes)

    add r7, r4, r5                      @ Desplazamiento total (fila + columna)
    ldrh r3, [r0, r7]

	push {r6, lr}

	mov r6, #7
    and r3, r3, r6						@ Obtener valor actual de la celda
    cmp r3, #0							@ Si valor == 0, aumentar celdas vacías y omitir propagación
    beq empty_cell_t

    add r3, #3                      	@ r8 = displace = (3 + r3)
    mov r6, #1
    lsl r6, r6, r3						@ Desplazar bit a la izquierda r3 posiciones

    push {r1, r2, lr}					@ Guardar índices de fila y columna, y el contador de celdas vacías

    bl update_row_candidates_thumb
    bl update_column_candidates_thumb

    pop {r1, r2, pc}

	push {r1, r2, lr}

    bl calc_region_indexes_thumb
    bl update_region_candidates_thumb

    pop {r1, r2, pc}				@ Restaurar índices y contador de celdas vacías
    b next_column_t

empty_cell_t:
	pop {r6, pc}
    add r6, r6, #1
    b next_column_t

next_column_t:
    add r2, r2, #1
    b thumb_loop_j

thumb_loop_j_end:
    add r1, r1, #1
    b thumb_loop_i

thumb_loop_i_end:
    mov r0, r10                          @ Almacenar el contador de celdas vacías en r0 para devolverlo como resultado
    bx lr

update_row_candidates_thumb:
    movs r1, #0
fila_loop_t:
    cmp r1, #9
    bge fin_fila_t

    lsl r2, r1, #5                   @ Desplazar la fila (r8 * 32)
    add r7, r2, r5                  @ r10 = desplazamiento total = fila + columna (columna fija para r5)

    ldrh r3, [r0, r7]

    bic r3, r3, r6                   @ celda &= ~(1 << displace) - Actualizar el bit candidato
    strh r3, [r0, r7]

    add r1, r1, #1
    b fila_loop_t

fin_fila_t:
    bx lr

update_column_candidates_thumb:
    movs r1, #0
col_loop_t:
    cmp r1, #9
    bge fin_col_t

    lsl r2, r1, #1                   @ Desplazar la columna (r8 * 2)
    add r7, r4, r2                  	@ r10 = desplazamiento total = fila + columna (fila fija para r4)

    ldrh r3, [r0, r7]

    bic r3, r3, r6                   @ celda &= ~(1 << displace) - Actualizar el bit candidato
    strh r3, [r0, r7]

    add r1, r1, #1
    b col_loop_t

fin_col_t:
    bx lr

calc_region_indexes_thumb:
    mov r3, r2
    mov r5, #0
col_index_t:
    cmp r3, #3                        @ Si es menor a 3, termina el cálculo de columna
    blt col_index_end_t

    sub r3, r3, #3                    @ Restas sucesivas para determinar la region de la celda (1°,2° o 3° region horizontal)
    add r5, r5, #3                    @ Aumentar #3 para ubicarse al inicio de la región correspondiente
    b col_index_t

col_index_end_t:
    movs r2, r5                       @ Guardar el índice calculado en r2 (columna)

    movs r3, r1
    movs r4, #0
row_index_t:
    cmp r3, #3                        @ Si es menor a 3, termina el cálculo de fila
    blt row_index_end_t
    sub r3, r3, #3                    @ Restas sucesivas para determinar la región de la celda (1°,2° o 3° region vertical)
    add r4, r4, #3                    @ Aumentar #3 para ubicarse al inicio de la región correspondiente
    b row_index_t

row_index_end_t:
    movs r1, r4                       @ Guardar el índice calculado en r1 (fila)

    add r4, r1, #3                    @ r4 = Límite superior de la fila
    add r5, r2, #3                    @ r5 = Límite superior de la columna

    bx lr

update_region_candidates_thumb:
    @ r0 = cuadricula
    @ r1 = indice inicial region (fila)
    @ r2 = indice inicial region (columna)
    @ r3 = valor_celda
    @ r4 = limite max region (fila)
    @ r5 = limite max region (columna)
    @ r6 = bit de desactivacion desplazado
    @ r7 = desplazamiento total (fila + columna)

region_row_loop_t:
    cmp r1, r4
    bge end_of_region_t

	push {r4}
region_col_loop_t:
	push {r5}						@ Backup del limite superior de la columna
    cmp r2, r5
    bge end_of_column_t

    lsl r4, r1, #5                  @ Desplazamiento fila (r1 * 32)
    lsl r5, r2, #1                  @ Desplazamiento columna (r2 * 2)
    add r7, r4, r5                 	@ Desplazamiento total de la celda (fila + columna)

    ldrh r3, [r0, r7]
    bic r3, r3, r6                    @ celda &= ~(1 << displace)
    strh r3, [r0, r7]

    add r2, r2, #1
	pop {r5}
    b region_col_loop_t

end_of_column_t:
    add r1, r1, #1
    sub r2, r2, #3
    pop {r4}						@ Restaurar el limite superior de la fila
    b region_row_loop_t

end_of_region_t:
    bx lr
################################################################################
.arm
sudoku_candidatos_init_arm:
    @ r0 = cuadricula
    @ r1 = fila
    @ r2 = columna
    @ r3 = valor actual
    @ r4 = desplazamiento fila
    @ r5 = desplazamiento columna
    @ r6 = 0x1FF0 lista de candidatos
    @ r7 = desplazamiento total

	MOV r9, r1						@ r9 = version propagar (C=0, ARM=1, THUMB=2)

    MOV r1, #0
    MOV r6, #0x1F00               	@ Cargar parte alta de (0x1F00)
    ORR r6, r6, #0x00F0           	@ Combinar parte baja (0x00F0) para obtener 0x1FF0

init_fila:
    CMP r1, #9
    BGE fin_init

    LSL r4, r1, #5					@ Desplazamiento a siguiente fila (r1 * 32 bytes)

    MOV r2, #0
init_columna:
    CMP r2, #9
    BGE fin_init_columna

    LSL r5, r2, #1					@ Desplazamiento a siguiente columna (r2 * 2 bytes)

    ADD r7, r4, r5        			@ Desplazamiento total (fila + columna)

    LDRH r3, [r0, r7]

   	AND r8, r3, #0x8000				@ Objeter valor de la pista
	CMP r8, #0x8000					@ Si pista == 1 se omite la inicializacion de candidatos
    BGE skip_init

    ORR r3, r3, r6        			@ celda |= 0x1FF0 - Activar todos los candidatos
    STRH r3, [r0, r7]

skip_init:
    ADD r2, r2, #1
    B init_columna

fin_init_columna:
    ADD r1, r1, #1
    B init_fila

fin_init:

@ Recorrer la cuadricula para llamar a las versiones de propagar

	MOV r10, #0							@ Contador de celdas vacias
	MOV r1, #0
fila_cuadricula:
	CMP r1, #9
	BGE fin_cuadricula

	LSL r4, r1, #5

	MOV r2, #0
recorrer_columna:
	CMP r2, #9
	BGE siguiente_fila

	LSL r6, r2, #1

	ADD r7, r4, r6

	LDRH r3, [r0, r7]

	AND r3, r3, #0xF				@celda_leer_valor()
	CMP r3, #0
	BEQ skip_propagation

	CMP r9, #0
	BEQ propagar_C

	CMP r9, #1
	BEQ propagar_ARM
skip_propagation:
	ADD r10, r10, #1
	B final_columna
propagar_C:
	STMED SP!, {r0-r12, r14}
	BL sudoku_candidatos_propagar_c
	LDMED SP!, {r0-r12, r14}
	B final_columna
propagar_ARM:
	STMED SP!, {r0-r12, r14}
	BL sudoku_candidatos_propagar_arm
	LDMED SP!, {r0-r12, r14}
	B final_columna
#propagar_THUMB:
#	BL sudoku_candidatos_propagar_arm
#	B final_columna
final_columna:
	ADD r2, r2, #1
	B recorrer_columna
siguiente_fila:
	ADD r1, r1, #1
	B fila_cuadricula
fin_cuadricula:
	MOV r0, r10
  	BX lr


@ Calcula el desplazamiento necesario para llegar a la celda, y llama a las funciones de propagacion (fila, columna y region)
sudoku_candidatos_propagar_arm:
	STMFD sp!, {r11, r12, lr}
	@ r0 = cuadricula
	@ r1 = indice fila
	@ r2 = indice columna
	@ r3 = valor actual celda
	@ r4 = desplazamiento de la fila
	@ r5 = desplazamiento de la columna
	@ r6 = bit desplazado (se usara para desactivar los candidatos)
	@ r7 = desplazamiento total (r4 + r5)

	LSL r4, r1, #5							@ Desplazamiento fila (r1 * 32 bytes)

	LSL r5, r2, #1							@ Desplazamiento columna (r2 * 2 bytes)

	ADD r7, r4, r5							@ Desplazamiento total (fila + columna)

	ADD r8, r3, #3							@ r8 = displace = (3 + r3)

	MOV r6, #1
	LSL r6, r6, r8							@ desplazar bit a la izquierda r8 posiciones

	LDRH r8, [r0, r7]

@ Actualiza los candidatos de la fila (verticalmente)
	MOV r9, #0
fila_loop:
    CMP r9, #9
    BGE fin_fila

    LSL r10, r9, #5               			@ Desplazar la fila (r9 * 32)
    ADD r11, r10, r5               			@ r11 = desplazamiento total = fila + columna (columna fija para r5)

    LDRH r8, [r0, r11]

    AND r12, r8, #0x8000
    CMP r12, #0x8000
    BEQ skip_row

    CMP r9, r1
    BEQ skip_row

    BIC r8, r8, r6               			@ celda &= ~(1 << displace) - Actualizar el bit candidato
    STRH r8, [r0, r11]
skip_row:
    ADD r9, r9, #1
    B fila_loop
fin_fila:
@ Actualiza los candidatos de la columna (Horizontalmente)
	MOV r9, #0
col_loop:
    CMP r9, #9
    BGE fin_col

    LSL r10, r9, #1               			@ Desplazar la columna (r9 * 2)
    ADD r11, r4, r10               			@ r11 = desplazamiento total = fila + columna (fila fija para r4)

    LDRH r8, [r0, r11]

    AND r12, r8, #0x8000
    CMP r12, #0x8000
    BEQ skip_column

    CMP r9, r2
    BEQ skip_column

    BIC r8, r8, r6               			@ celda &= ~(1 << displace) - Actualizar bit candidato
    STRH r8, [r0, r11]
skip_column:
    ADD r9, r9, #1
    B col_loop
fin_col:
@ Calcula el limite inferior (esquina superior izquierda) y limite superior de la region 3x3 correspondiente a la celda
	MOV r8, r1
	MOV r9, #0
row_index:
	CMP r8, #3
	BLT row_index_end						@ Si es menor a 3, termina el calculo de fila

	SUB r8, r8, #3							@ Restas sucesivas para determinar la region de la celda (1°,2° o 3° region vertical)
	ADD r9, r9, #3							@ Aumentar #3 para ubicarse al inicio de la region correspondiente
	B row_index
row_index_end:
	MOV r7, r9								@ Guardar el indice calculado en r8 (fila)

	MOV r8, r2
	MOV r9, #0
col_index:
	CMP r8, #3
	BLT col_index_end						@ Si es menor a 3, termina el calculo de columna

	SUB r8, r8, #3							@ Restas sucesivas para determinar la region de la celda (1°,2° o 3° region horizontal)
	ADD r9, r9, #3							@ Aumentar #3 para ubicarse al inicio de la region correspondiente
	B col_index
col_index_end:
	MOV r8, r9								@ Guardar el indice calculado en r7 (columna)

	ADD r9, r7, #3							@ r9 = Limite superior de la fila
	ADD r10, r8, #3							@ r10 = Limite superior de la columna
@ Actualiza los candidatos de la region 3x3
region_row_loop:
	CMP r7, r9
	BGE end_of_region
region_col_loop:
	CMP r8, r10
	BGE end_of_column

	LSL r4, r7, #5							@ Desplazamiento fila (r7 * 32)
	LSL r5, r8, #1							@ Desplazamiento columna (r10 * 2)
	ADD r11, r4, r5							@ Desplazamiento total de la celda (fila + columna)

	LDRH r12, [r0, r11]

	AND r4, r12, #0x8000
	CMP r4, #0x8000
	BEQ skip_cell

	CMP r7, r1
	BEQ skip_cell

	CMP r8, r2
	BEQ skip_cell

	BIC r12, r12, r6						@ celda &= ~(1 << displace) - Actualizar bit candidato
	STRH r12, [r0, r11]
skip_cell:
	ADD r8, r8, #1
	B region_col_loop
end_of_column:
	ADD r7, r7, #1
	SUB r8, r8, #3						@ Regresar a la primera columa de la región
	B region_row_loop
end_of_region:
	LDMFD sp!, {r11, r12, lr}
	BX lr

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

.extern		sudoku_candidatos_propagar_c
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
