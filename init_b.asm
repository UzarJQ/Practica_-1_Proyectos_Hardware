.text

#        ENTRY                  /*  mark the first instruction to call */
.global start
.global sudoku_candidatos_propagar_arm
.global sudoku_candidatos_init_arm
.global sudoku_candidatos_propagar_thumb

################################################################################
sudoku_candidatos_propagar_thumb:

    PUSH {r3-r7, LR}          // Guarda los registros r3-r7 y el Link Register (LR) en la pila

    // Inicialización de variables
    mov r4, #0                // Inicializa r4 en 0, se usará para calcular el desplazamiento de la celda
    mov r5, r1                // r5 = fila
    mov r6, r2                // r6 = columna

    // Cálculo del desplazamiento en la cuadrícula basado en fila y columna
    lsl r5, #5                // Multiplica fila por 32 (2^5) para calcular el desplazamiento de la fila
    add r4, r4, r5            // Añade el desplazamiento de la fila a r4
    lsl r6, #1                // Multiplica columna por 2 (2 bytes por celda)
    add r4, r4, r6            // Añade el desplazamiento de la columna a r4

    // Cargar el valor de la celda actual y aislar los 4 bits de menor peso
    ldrh r3, [r0, r4]         // Carga el valor de la celda en r3
    mov r4, #15               // Máscara de 4 bits (0xF)
    and r3, r3, r4            // Extrae los 4 bits de menor peso (valor fijo de la celda)

    // Cálculo del patrón de exclusión para eliminar candidatos
    sub r3, r3, #1            // Resta 1 al valor de la celda
    add r3, r3, #4            // Añade 4 para obtener el índice del bit correspondiente al valor de la celda
    mov r4, #1                // Inicializa r4 con 1
    lsl r4, r4, r3            // Desplaza 1 hacia la izquierda por el valor del índice calculado
    mvn r7, r4                // Complementa el valor de r4, creando una máscara de exclusión


  // Bucle para recorrer las filas
    mov r3, #0                // Inicializa el contador de filas a 0
recorrer_filas_th:
    cmp r3, #9                // Compara el contador de filas con 9
    beq fin_recorrer_filas_th  // Si es igual a 9, termina el bucle de filas

    cmp r3, r2                // Compara la fila actual con la fila de la celda que se está propagando
    beq siguiente_fila_th      // Si es la misma fila, salta a la siguiente fila

    // Cálculo de la dirección de la celda en la fila actual
    mov r5, r1                // Carga la fila en r5
    mov r6, r3                // Carga el contador de filas en r6
    mov r4, #0                // Inicializa r4 para calcular el desplazamiento

    lsl r5, #5                // Multiplica fila por 32
    add r4, r4, r5            // Añade el desplazamiento de la fila a r4
    lsl r6, #1                // Multiplica columna por 2
    add r4, r4, r6            // Añade el desplazamiento de la columna a r4

    // Cargar el valor de la celda y aplicar la máscara de exclusión
    ldrh r5, [r0, r4]         // Carga el valor de la celda en r5
    mov r6, r5                // Guarda el valor original de la celda en r6
    and r5, r5, r7            // Aplica la máscara de exclusión a los candidatos
    cmp r5, r6                // Compara el valor nuevo con el original
    beq siguiente_fila_th      // Si no cambió, pasa a la siguiente fila
    strh r5, [r0, r4]         // Si cambió, guarda el nuevo valor en la celda

siguiente_fila_th:
    add r3, #1                // Incrementa el contador de filas
    b recorrer_filas_th        // Vuelve al inicio del bucle de filas

fin_recorrer_filas_th:

    // Bucle para recorrer las columnas
    mov r3, #0                // Inicializa el contador de columnas a 0
recorrer_columnas_th:
    cmp r3, #9                // Compara el contador de columnas con 9
    beq fin_recorrer_columnas_th // Si es igual a 9, termina el bucle de columnas

    cmp r3, r1                // Compara la columna actual con la columna de la celda que se está propagando
    beq siguiente_columna_th   // Si es la misma columna, salta a la siguiente columna

    // Cálculo de la dirección de la celda en la columna actual
    mov r4, #0                // Inicializa r4 para calcular el desplazamiento
    mov r5, r3                // Carga el contador de columnas en r5
    mov r6, r2                // Carga la columna en r6

    lsl r5, #5                // Multiplica fila por 32
    add r4, r4, r5            // Añade el desplazamiento de la fila a r4
    lsl r6, #1                // Multiplica columna por 2
    add r4, r4, r6            // Añade el desplazamiento de la columna a r4

    // Cargar el valor de la celda y aplicar la máscara de exclusión
    ldrh r5, [r0, r4]         // Carga el valor de la celda en r5
    mov r6, r5                // Guarda el valor original de la celda en r6
    and r5, r5, r7            // Aplica la máscara de exclusión a los candidatos
    cmp r5, r6                // Compara el valor nuevo con el original
    beq siguiente_columna_th   // Si no cambió, pasa a la siguiente columna
    strh r5, [r0, r4]         // Si cambió, guarda el nuevo valor en la celda

siguiente_columna_th:
    add r3, #1                // Incrementa el contador de columnas
    b recorrer_columnas_th     // Vuelve al inicio del bucle de columnas

fin_recorrer_columnas_th:

    // Cálculo para iterar sobre la región 3x3 (bloque del Sudoku)
    mov r3, r1                // Carga la fila en r3
for_resto_fila_th:
    cmp r3, #2                // Compara si la fila es menor o igual a 2
    ble fin_resto_fila_th      // Si lo es, termina el bucle
    sub r3, r3, #3            // Resta 3 para calcular el inicio de la región
    b for_resto_fila_th        // Repite hasta que r3 <= 2

fin_resto_fila_th:
    sub r3, r1, r3            // Corrige el valor de r3

    mov r4, r2                // Carga la columna en r4
for_resto_columna_th:
    cmp r4, #2                // Compara si la columna es menor o igual a 2
    ble fin_resto_columna_th   // Si lo es, termina el bucle
    sub r4, r4, #3            // Resta 3 para calcular el inicio de la región
    b for_resto_columna_th     // Repite hasta que r4 <= 2

fin_resto_columna_th:
    sub r4, r2, r4            // Corrige el valor de r4

    // Recorre las celdas dentro de la región 3x3
    mov r5, r3                // Carga el inicio de la región en r5
    mov r6, r4                // Carga el inicio de la región en r6

    add r3, #3                // Define el límite de la región en filas
    add r4, #3                // Define el límite de la región en columnas

recorrer_region_fil_th:
    cmp r5, r3                // Compara r5 con el límite de la región en filas
    beq fin_recorrer_region_fil_th // Si r5 llega al límite, termina el bucle de la región

    recorrer_region_col_th:
        cmp r6, r4            // Compara r6 con el límite de la región en columnas
        beq fin_recorrer_region_col_th // Si r6 llega al límite, termina el bucle de la región

        // Evita la celda que inició la propagación
        cmp r5, r1            // Compara si la fila es la misma que la original
        beq siguiente_region_col_th // Si es la misma, salta a la siguiente columna
        cmp r6, r2            // Compara si la columna es la misma que la original
        beq siguiente_region_col_th // Si es la misma, salta a la siguiente columna

        // Cálculo de la dirección de la celda dentro de la región
        push {r2-r4}          // Guarda los registros temporales
        mov r2, #0            // Inicializa r2 en 0
        mov r3, r5            // Carga r5 en r3 para calcular el desplazamiento de la fila
        mov r4, r6            // Carga r6 en r4 para calcular el desplazamiento de la columna

        lsl r3, #5            // Multiplica fila por 32
        add r2, r2, r3        // Añade el desplazamiento de la fila a r2
        lsl r4, #1            // Multiplica columna por 2
        add r2, r2, r4        // Añade el desplazamiento de la columna a r2

        // Cargar el valor de la celda y aplicar la máscara de exclusión
        ldrh r3, [r0, r2]     // Carga el valor de la celda en r3
        mov r4, r3            // Guarda el valor original de la celda en r4
        and r4, r4, r7        // Aplica la máscara de exclusión a los candidatos
        cmp r3, r4            // Compara el valor nuevo con el original
        beq siguiente_region_col_th2 // Si no cambió, pasa a la siguiente columna
        strh r4, [r0, r2]     // Si cambió, guarda el nuevo valor en la celda

siguiente_region_col_th2:
        pop {r2-r4}           // Restaura los registros temporales
siguiente_region_col_th:
        add r6, #1            // Incrementa el contador de columnas
        b recorrer_region_col_th // Vuelve al inicio del bucle de columnas en la región

fin_recorrer_region_col_th:
    add r5, #1                // Incrementa el contador de filas
    sub r6, r4, #3            // Reinicia el contador de columnas al inicio de la región
    b recorrer_region_fil_th   // Vuelve al inicio del bucle de filas en la región

fin_recorrer_region_fil_th:
    pop {r3-r7}               // Restaura los registros
    bx lr                     // Retorna de la función

################################################################################
.arm
sudoku_candidatos_init_arm:
	push {r11, r12, lr}
    @ r0 = cuadricula
    @ r1 = fila
    @ r2 = columna
    @ r3 = valor actual
    @ r4 = desplazamiento fila
    @ r5 = desplazamiento columna
    @ r6 = 0x1FF0 lista de candidatos
    @ r7 = desplazamiento total

    mov r1, #0
    mov r6, #0x1F00               	@ Cargar parte alta de (0x1F00)
    orr r6, r6, #0x00F0           	@ Combinar parte baja (0x00F0) para obtener 0x1FF0

init_fila:
    cmp r1, #9
    bge fin_init_fila

    lsl r4, r1, #5					@ Desplazamiento a siguiente fila (r1 * 32 bytes)

    mov r2, #0
init_columna:
    cmp r2, #9
    bge fin_init_columna

    lsl r5, r2, #1					@ Desplazamiento a siguiente columna (r2 * 2 bytes)

    add r7, r4, r5        			@ Desplazamiento total (fila + columna)

    ldrh r3, [r0, r7]

   	and r8, r3, #0x8000				@ Objeter valor de la pista
	cmp r8, #0x8000					@ Si pista == 1 se omite la inicializacion de candidatos
    bge skip_init

    orr r3, r3, r6        			@ celda |= 0x1FF0 - Activar todos los candidatos
    strh r3, [r0, r7]

skip_init:
    add r2, r2, #1
    b init_columna

fin_init_columna:
    add r1, r1, #1
    b init_fila

fin_init_fila:
	mov r1, #0
	mov r2, #0

	mov r10, #2								@ Selector de version propagar (1 = ARM, 2 = THUMB)
	cmp r10, #1
	beq propagar_arm

	cmp r10, #2
	beq propagar_thumb

propagar_arm:
	bl sudoku_candidatos_propagar_arm
	b fin_init
propagar_thumb:
	bl sudoku_candidatos_propagar_thumb
	b fin_init

fin_init:
	pop {r11, r12, lr}
    bx lr


@ Recorre la cuadricula llamando a las funciones de propagacion (fila, columna y region) SI la celda tiene un valor distinto a 0
sudoku_candidatos_propagar_arm:
	push {r0, r5, r11, r12, lr}
	@ r0 = cuadricula
	@ r1 = indice fila
	@ r2 = indice columna
	@ r3 = valor actual celda
	@ r4 = desplazamiento de la fila
	@ r5 = desplazamiento de la columna
	@ r6 = bit desplazado (se usara para desactivar los candidatos)
	@ r7 = desplazamiento total (r4 + r5)
	@ r10 = contador de celdas vacias
	@ r8-r12 = registros de trabajo
	mov r10, #0
loop_i:
	cmp r1, #9
	bge loop_i_end

	lsl r4, r1, #5						@ Desplazamiento a siguiente fila (r1 * 32 bytes)

	mov r2, #0
loop_j:
	cmp r2, #9
	bge loop_j_end						@ Comprobar si se ha llegado a la ultima columna

	lsl r5, r2, #1						@ Desplazamiento a siguiente columna (r2 * 2 bytes)

	add r7, r4, r5						@ Desplazamiento total (fila + columna)
	ldrh r3, [r0, r7]

	and r3, r3, #0xF					@ Objeter valor actual de la celda (celda_leer_valor)
	cmp r3, #0							@ Si valor == 0 se aumentan las celdas vacias y se omite la propagacion
	beq empty_cell

	add r8, r3, #3						@ r8 = displace = (3 + r3)
	mov r6, #1
	lsl r6, r6, r8						@ desplazar bit a la izquierda r8 posiciones

	push {r1, r2, r10, lr}				@ Backup de indices de fila y columna, y el contador de celdas vacias

	bl arm_update_row_candidates		@ Actualizar filas

	bl arm_update_column_candidates		@ Actualizar columnas

	bl arm_calc_region_indexes				@ Calcular indices de la region
	bl arm_update_region_candidates		@ Actualizar region
	pop {r1, r2, r10, lr}				@ Restaurar valor de los indices y las celdas vacias

	b next_column

empty_cell:
	add r10, r10, #1
	b next_column

next_column:
	add r2, r2, #1
	b loop_j
loop_j_end:
	add r1, r1, #1
	b loop_i
loop_i_end:
	pop {r0, r5, r11, r12, lr}			@ Restaurar valor de los punteros a funciones y cuadricula
	mov r0, r10							@ Almacenar el contador de celdas vacias en r0 para devolverse como resultado de la funcion
	bx lr								@ Devolver el control a la funcion en C


arm_update_row_candidates:
    mov r8, #0
fila_loop:
    cmp r8, #9
    bge fin_fila

    lsl r9, r8, #5               		@ Desplazar la fila (r8 * 32)
    add r10, r9, r5               		@ r10 = desplazamiento total = fila + columna (columna fija para r5)

    ldrh r3, [r0, r10]

    bic r3, r3, r6               		@ celda &= ~(1 << displace) - Actualizar el bit candidato
    strh r3, [r0, r10]

    add r8, r8, #1
    b fila_loop

fin_fila:
    bx lr

arm_update_column_candidates:
    mov r8, #0
col_loop:
    cmp r8, #9
    bge fin_col

    lsl r9, r8, #1               		@ Desplazar la columna (r8 * 2)
    add r10, r4, r9               		@ r10 = desplazamiento total = fila + columna (fila fija para r4)

    ldrh r3, [r0, r10]

    bic r3, r3, r6               		@ celda &= ~(1 << displace) - Actualizar bit candidato
    strh r3, [r0, r10]

    add r8, r8, #1
    b col_loop

fin_col:
    bx lr


arm_calc_region_indexes:
	mov r8, r2
	mov r9, #0
col_index:
	cmp r8, #3
	blt col_index_end					@ Si es menor a 3, termina el calculo de columna

	sub r8, r8, #3						@ Restas sucesivas para determinar la region de la celda (1°,2° o 3° region horizontal)
	add r9, r9, #3						@ Aumentar #3 para ubicarse al inicio de la region correspondiente
	b col_index
col_index_end:
	mov r2, r9							@ Guardar el indice calculado en r1 (fila)

	mov r8, r1
	mov r9, #0
row_index:
	cmp r8, #3
	blt row_index_end					@ Si es menor a 3, termina el calculo de fila

	sub r8, r8, #3						@ Restas sucesivas para determinar la region de la celda (1°,2° o 3° region vertical)
	add r9, r9, #3						@ Aumentar #3 para ubicarse al inicio de la region correspondiente
	b row_index
row_index_end:
	mov r1, r9							@ Guardar el indice calculado en r2 (columna)

	add r8, r1, #3						@ r8 = Limite superior de la fila
	add r9, r2, #3						@ r9 = Limite superior de la columna

	bx lr

arm_update_region_candidates:
	@ r0 = cuadricula
	@ r1 = indice inicial region (fila)
	@ r2 = indice inicial region (columna)
	@ r3 = valor_celda
	@ r6 = bit e desactivacion desplazado
	@ r8 = limite max region (fila)
	@ r9 = limite max region (columna)

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
