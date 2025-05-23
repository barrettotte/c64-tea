        .encoding "petscii_upper"
        .pc = $c000 "main"      // entry point

start:  ldx #0                  // x = 0

loop:   lda msg,x               // a = msg[x]
        beq done                // exit loop if null terminator

        jsr $ffd2               // CHROUT routine
        inx                     // x++
        jmp loop                // next loop iter
done:   
        rts                     // exit program

msg:    .text "HELLO FROM ASM"
        .byte 13                // newline
        .byte 0
