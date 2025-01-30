[org 0x100]
JMP START


ballRow: dw 23
ballCol: dw 40

addRow: dw -1
addCol: dw 1

colBat1: dW 30
colBat2: dW 30


turn: dw 1 ; 1 IS TOP PLAYER, 2 IS BOTTOM PLAYER
oldisr: dd 0

COUNT: dw 0
STRING: DW "GAME OVER", 0


clear_screen:
    PUSH BP
    MOV BP,SP
    PUSHA

    MOV AX,0XB800
    MOV ES,AX
    MOV AX,0
    MOV CX,4000
    MOV DI,0
    REP STOSW

    POPA
    MOV SP,BP
    POP BP

    RET

clearRow:
    ;clears the row pushed to it, 1 is top row, 25 is bottom row
    PUSH BP
    MOV BP,SP
    PUSHA

    MOV AX,0XB800
    MOV ES,AX

    MOV AX,[BP+4]
    SUB AX,1
    MOV BX,160
    MUL BX

    MOV DI,AX

    MOV AX,0
    MOV CX,80

    REP STOSW

    POPA
    MOV SP,BP
    POP BP

    RET 2

DRAW_PAD_1:
    PUSH BP
    MOV BP,SP
    PUSHA

    PUSH WORD 1
    CALL clearRow

    MOV AX,0XB800
    MOV ES,AX
    MOV DI,[colBat1]
    SHL DI,1
    MOV AL,'*'
    MOV AH,01110000B

    MOV CX,20
    REP STOSW

    POPA
    MOV SP,BP
    POP BP

RET

DRAW_PAD_2:
    PUSH BP
    MOV BP,SP
    PUSHA

    PUSH WORD 25
    CALL clearRow

    MOV AX,0XB800
    MOV ES,AX
    MOV DI,[colBat2]
    SHL DI,1
    ADD DI,4000-160
    MOV AL,'*'
    MOV AH,01110000B

    MOV CX,20
    REP STOSW

    POPA
    MOV SP,BP
    POP BP

RET


clear_current:
    ;clears the current position of the ball
    PUSH BP
    MOV BP,SP
    PUSHA

    MOV AX,0XB800
    MOV ES,AX

    MOV AX,[ballRow]
    MOV BX,160
    MUL BX

    ADD AX,[ballCol]
    ADD AX,[ballCol]  ;NOW AX HAS THE CURRENT BYTE OF THE BALL

    MOV DI,AX
    MOV AX,0
    STOSW

    POPA
    MOV SP,BP
    POP BP

RET 


updateBallPos:
    MOV AX,[cs:addRow]
    ADD WORD [cs:ballRow], AX ;UPDATE THE ROW OF THE BALL
    MOV AX,[cs:addCol]
    ADD WORD [cs:ballCol], AX ;UPDATE THE COLUMN OF THE BALL
    ret

print:
    MOV WORD [CS:COUNT], 0

    call clear_current
    CALL updateBallPos

    MOV AX,[ballRow]
    MOV BX,160
    MUL BX

    ADD AX,[ballCol]
    ADD AX,[ballCol]  ;NOW AX HAS THE CURRENT BYTE OF THE BALL
    MOV DI,AX

    MOV AX,0XB800
    MOV ES,AX

    MOV AL,' '
    ;MOV AH,01110111B
    MOV AH,01110111B

    MOV [ES:DI],AX

	JMP printEnd



printnum: push bp
 mov bp, sp
 push es
 push ax
 push bx
 push cx
 push dx
 push di
 mov ax, 0xb800
 mov es, ax ; point es to video base
 mov ax, [bp+4] ; load number in ax
 mov bx, 10 ; use base 10 for division
 mov cx, 0 ; initialize count of digits
nextdigit: mov dx, 0 ; zero upper half of dividend
 div bx ; divide by 10
 add dl, 0x30 ; convert digit into ascii value
 push dx ; save ascii value on stack
 inc cx ; increment count of values
 cmp ax, 0 ; is the quotient zero
 jnz nextdigit ; if no divide it again
 mov di, 140 ; point di to 70th column
nextpos: pop dx ; remove a digit from the stack
 mov dh, 0x07 ; use normal attribute
 mov [es:di], dx ; print char on screen
 add di, 2 ; move to next screen location
 loop nextpos ; repeat for all digits on stack
 pop di
 pop dx
 pop cx
 pop bx
 pop ax 
 pop es
 pop bp
 RET 2

SCORE: DW 0

GAME_OVER:
    MOV AX, 0XB800
    MOV ES, AX

    MOV DI, 160
    MOV SI, STRING
    MOV CX, 9

    A:
    MOV AL, [SI]
    STOSW
    ADD SI,1
    LOOP A

    MOV WORD [CS:addRow], 0
    MOV WORD [CS:addCol], 0

    JMP printEnd

B1_RIGHT:
    ; MOV AX, [colBat1]
    ; ADD AX, 1
    ; MOV [colBat1], AX
    ADD WORD [colBat1], 1
    CALL DRAW_PAD_1
    JMP exit

B1_LEFT:
    ; MOV AX, [colBat1]
    ; SUB AX, 1
    ; MOV [colBat1], AX
    SUB WORD [colBat1], 1
    CALL DRAW_PAD_1
    JMP exit
    
B2_RIGHT:
    ; MOV AX, [colBat2]
    ; ADD AX, 1
    ; MOV [colBat2], AX
    ADD WORD [colBat2], 1
    CALL DRAW_PAD_2    
    JMP exit

B2_LEFT:
    ; MOV AX, [colBat2]
    ; SUB AX, 1
    ; MOV [colBat2], AX 
    SUB WORD [colBat2], 1   
    CALL DRAW_PAD_2    
    JMP exit


MOVE_LEFT:
    CMP WORD [turn], 1
    JE B1_LEFT
    JMP B2_LEFT

MOVE_RIGHT:
    CMP WORD [turn], 1
    JE B1_RIGHT
    JMP B2_RIGHT


DISPLAY_ASTERISK:
	push ax

    PUSH WORD [CS:SCORE]
    CALL printnum
    
    INC WORD [CS:COUNT]
    CMP WORD [CS:COUNT], 2
    JZ print

    IN AL, 60H
    CMP AL, 0X4B
    JZ MOVE_LEFT

    CMP AL, 0X4D
    JZ MOVE_RIGHT

    CMP WORD [CS:ballRow], 1
    JLE TOUCHED_TOP

    CMP WORD [CS:ballCol], 78
    JAE TOUCHED_RIGHT

    CMP WORD [CS:ballRow], 23
    JAE TOUCHED_BOTTOM

    CMP WORD [CS:ballCol], 1
    JLE TOUCHED_LEFT

    CMP WORD [CS:SCORE], 5
    JAE GAME_OVER

	printEnd:
	
	exit:
	pop ax
	JMP FAR [CS:oldisr]

IRET


CHECK:
    MOV AX,[CS:colBat1]
    ADD AX, 20
    CMP WORD [CS:ballCol], AX
    JLE print
    INC WORD [CS:SCORE]
    JMP print

TOUCHED_TOP:
    MOV AX, 1
    MOV [cs:addRow], AX ;CHANGE THE DIRECTION OF THE BALL FROM TOP TO BOTTON, THE COLUMN REMAINS THE SAME
    ;CHANGE THE TURN
    MOV WORD [cs:turn], 2
    MOV AX, [CS:colBat1]

    CMP WORD [CS:ballCol], AX
    JAE CHECK

    INC WORD [CS:SCORE]

    JMP print

TOUCHED_RIGHT:
    MOV AX, -1
    MOV [cs:addCol], AX ;CHANGE THE DIRECTION OF THE BALL FROM RIGHT TO LEFT, THE ROW REMAINS THE SAME
    JMP print

TOUCHED_BOTTOM:
    MOV AX, -1
    MOV [cs:addRow], AX ;CHANGE THE DIRECTION OF THE BALL FROM BOTTOM TO TOP, THE COLUMN REMAINS THE SAME
    MOV WORD [cs:turn], 1
    JMP print

TOUCHED_LEFT:
    MOV AX, 1
    MOV [cs:addCol], AX ;CHANGE THE DIRECTION OF THE BALL FROM LEFT TO RIGHT, THE ROW REMAINS THE SAME
    JMP print

START:

    CALL clear_screen

    PUSH 1
    call clearRow

    PUSH 25
    call clearRow

    CALL DRAW_PAD_1
    CALL DRAW_PAD_2

    XOR AX, AX
	MOV ES,AX
	MOV DI,0
	
	MOV ax, [es:8*4]
	MOV [oldisr], ax ; save offset of old routine
	MOV ax, [es:8*4+2]
	MOV [oldisr+2], ax

    CLI
	MOV WORD [ES:8*4], DISPLAY_ASTERISK
	MOV [ES:8*4+2], CS
	STI
	MOV DX,START
	ADD dx, 15 ; round up to next para
	MOV cl, 4
	SHR dx, cl 

    
    ; ;UNHOOKING THE TIMER INTERRUPT
    ; MOV AX,[oldisr]
    ; MOV [ES:8*4],AX
    ; MOV AX,[oldisr+2]
    ; MOV [ES:8*4+2],AX


    JMP $

    mov ax,0x4c00
    int 0x21
