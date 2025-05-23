// output HELLO WORLD

        .encoding "petscii_upper"
        * = $c000               // entry point

start:  ldx #$00                // x = 0
loop:   lda htxt,x              // a = htxt[x]
        beq done                // exit loop if null terminator
        jsr $ffd2               // CHROUT routine
        inx                     // x++
        jmp loop                // next loop iter
done:   rts                     // exit program

htxt:   .text "HELLO WORLD"
        .byte 0
