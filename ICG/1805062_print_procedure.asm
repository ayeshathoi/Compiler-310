;----------------------------------------------------------------------------------;
; OUTPUTS A SIGNED 16-BIT-INT STORED IN AX
PRINT_INT PROC

    CMP AX, 0H              ; IF AX IS 0, PRINT A 0 AND EXIT
    JNE PRINT_INT_NEXT
    MOV DL, '0'
    MOV AH, 2
    INT 21H
    JMP PRINT_INT_RET

    PRINT_INT_NEXT:
    MOV CX, 0H
    MOV DX, 0H

    ; CHECK IF AX IS -VE
    CMP AX, 0H
    JGE PROCESS
    NEG AX
    MOV BX, AX              ; TEMPORARILY STORE AX, IN BX

    MOV DL, '-'
    MOV AH, 2
    INT 21H

    MOV AX, BX              ; RETRIEVE BACK AX
    MOV CX, 0H
    MOV DX, 0H

    PROCESS:
        ; GO TO PRINT IF AX DIMINISHED
        CMP AX, 0H
        JE PRINT

        MOV BX, 10D
        DIV BX              ; AX/BX -> AX/10 => QUOTIENT AX, REMAINDER DX

        PUSH DX             ; PUSH LAST DIGIT IN STACK
        INC CX              ; INC COUNT i,e INC STACK SIZE
        XOR DX, DX          ; RESET DX
        JMP PROCESS
    PRINT:
        CMP CX, 0H          ; CHECK IF STACK EMPTY i.e IF COUNT IS 0
        JE PRINT_INT_RET

        POP DX              ; POP FROM STACK
        ADD DX, '0'
        MOV AH, 2           ; PRINT TOP OF STACK CHARACTER
        INT 21H

        DEC CX
        JMP PRINT

    PRINT_INT_RET:

RET
PRINT_INT ENDP
;----------------------------------------------------------------------------------