// Tiny Encryption Algorithm (TEA)

.encoding "petscii_upper"

.pc = $c000 "tea-subroutines" // entry point

// ==========================================================
// Constants
// ==========================================================

.const ROUNDS = 32

// Memory address from BASIC
.const BAS_MODE = $C800 // mode (1 byte), 0=encrypt, 1=decrypt
.const BAS_DATA = $C801 // data block (8 bytes), V0-V1
.const BAS_KEY =  $C809 // key (16 bytes), K0-K3

// TEA deltas - 2^(32)/phi = 0x9E3779B9
.const DELTA0 = $B9
.const DELTA1 = $79
.const DELTA2 = $37
.const DELTA3 = $9E

// Decrypt sum start - DELTA * ROUNDS = 0x9E3779B9 * 32 = 0xC6EF3720
.const DSUM0 = $20
.const DSUM1 = $37
.const DSUM2 = $EF
.const DSUM3 = $C6

// Working memory addresses ($C900+)
.const V0 =          $C900  // data word 0 (4 bytes)
.const V1 =          $C904  // data word 1 (4 bytes)
.const SUM =         $C908  // accumulator (4 bytes)
.const K0 =          $C90C  // key word 0 (4 bytes)
.const K1 =          $C910  // key word 1 (4 bytes)
.const K2 =          $C914  // key word 2 (4 bytes)
.const K3 =          $C918  // key word 3 (4 bytes)
.const TMP0 =        $C91C  // temp (4 bytes)
.const TMP1 =        $C920  // temp (4 bytes)
.const ROUND_COUNT = $C924  // round counter (1 byte)
.const MODE        = $C925  // TEA mode (1 byte)

// Kernal addresses
.const CHROUT = $FFD2 // CHROUT - character out

// ==========================================================
// Macros
// ==========================================================

// print newline
.macro print_cr() {
    lda #$0D    // carriage return
    jsr CHROUT  // print to screen
}

// print 32-bit value as hex
.macro print32(address) {
    .const __addr = address

    ldx #0               // start at LSB
!_print32_loop:          // loop over all bytes
    lda __addr, x        // load current byte
    pha                  // save byte to stack for low nibble

    // print high nibble
    lsr                  // a = byte >> 1
    lsr                  // a = byte >> 2
    lsr                  // a = byte >> 3
    lsr                  // a = byte >> 4
    jsr print_hex_nibble // print high nibble to screen

    // print low nibble
    pla                  // restore byte
    and #$0F             // clear high nibble
    jsr print_hex_nibble // print low nibble to screen

    lda #$20             // space
    jsr CHROUT           // print space to screen

    inx                  // x++ (toward MSB)
    cpx #4
    bne !_print32_loop-  // loop until all four bytes printed
}

// copy 32-bit value from src to dest: dest = src
.macro copy32(dest, src) {
    lda src
    sta dest
    lda src+1
    sta dest+1
    lda src+2
    sta dest+2
    lda src+3
    sta dest+3
}

// add 32-bit values: dest = dest + src
.macro add32(dest, src) {
    clc
    lda dest
    adc src
    sta dest
    lda dest+1
    adc src+1
    sta dest+1
    lda dest+2
    adc src+2
    sta dest+2
    lda dest+3
    adc src+3
    sta dest+3
}

// subtract 32-bit values: dest = dest - src
.macro sub32(dest, src) {
    sec
    lda dest
    sbc src
    sta dest
    lda dest+1
    sbc src+1
    sta dest+1
    lda dest+2
    sbc src+2
    sta dest+2
    lda dest+3
    sbc src+3
    sta dest+3
}

// xor 32-bit values: dest = dest ^ src
.macro xor32(dest, src) {
    lda dest
    eor src
    sta dest
    lda dest+1
    eor src+1
    sta dest+1
    lda dest+2
    eor src+2
    sta dest+2
    lda dest+3
    eor src+3
    sta dest+3
}

// 32-bit shift left 4 bits: val = val << 4
.macro shl4_32(val) {
    .for (var i = 0; i < 4; i++) {
        asl val
        rol val+1
        rol val+2
        rol val+3
    }
}

// 32-bit shift right 5 bits: val = val >> 5
.macro shr5_32(val) {
    .for (var i = 0; i < 5; i++) {
        lsr val+3
        ror val+2
        ror val+1
        ror val
    }
}

// ==========================================================
// Main
// ==========================================================

start:                         // entry point
        lda #0
        tax
        tay

        jsr load_data          // load v0-v1, k0-k3 into zero page

        // print32(V0)
        // print_cr()
        // print32(V1)
        // print_cr()

        lda BAS_MODE           // load mode
        sta MODE               // store mode

        beq do_encrypt         // if mode=0, encrypt
        jmp decrypt            // mode=1, go to decrypt
do_encrypt:
        jmp encrypt            // mode=0, go to encrypt

decrypt:
        // init decrypt
        lda #DSUM0
        sta SUM
        lda #DSUM1
        sta SUM+1
        lda #DSUM2
        sta SUM+2
        lda #DSUM3
        sta SUM+3

        lda #ROUNDS            // get rounds
        sta ROUND_COUNT        // init round counter
decrypt_loop:                  // decrypt multiple rounds

        // ======== PART ONE ========
        // v1 -= ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
        copy32(TMP0, V0)       // tmp0 = v0
        shl4_32(TMP0)          // tmp0 = v0 << 4
        add32(TMP0, K2)        // tmp0 = (v0 << 4) + k2
        copy32(TMP1, V0)       // tmp1 = v0
        add32(TMP1, SUM)       // tmp1 = v0 + sum
        xor32(TMP0, TMP1)      // tmp0 = ((v0 << 4) + k2) ^ (v0 + sum)
        copy32(TMP1, V0)       // tmp1 = v0
        shr5_32(TMP1)          // tmp1 = v0 >> 5
        add32(TMP1, K3)        // tmp1 = (v0 >> 5) + k3
        xor32(TMP0, TMP1)      // tmp0 = ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3)
        sub32(V1, TMP0)        // v1 -= tmp0

        // ======== PART TWO ========
        // v0 -= ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        copy32(TMP0, V1)       // tmp0 = v1
        shl4_32(TMP0)          // tmp0 = v1 << 4
        add32(TMP0, K0)        // tmp0 = (v1 << 4) + k0
        copy32(TMP1, V1)       // tmp1 = v1
        add32(TMP1, SUM)       // tmp1 = v1 + sum
        xor32(TMP0, TMP1)      // tmp0 = ((v1 << 4) + k0) ^ (v1 + sum)
        copy32(TMP1, V1)       // tmp1 = v1
        shr5_32(TMP1)          // tmp1 = v1 >> 5
        add32(TMP1, K1)        // tmp1 = (v1 >> 5) + k1
        xor32(TMP0, TMP1)      // tmp0 = ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1)
        sub32(V0, TMP0)        // v0 -= tmp0

        // sum -= DELTA
        sec
        lda SUM
        sbc #DELTA0
        sta SUM
        lda SUM+1
        sbc #DELTA1
        sta SUM+1
        lda SUM+2
        sbc #DELTA2
        sta SUM+2
        lda SUM+3
        sbc #DELTA3
        sta SUM+3

        dec ROUND_COUNT        // count--
        bne decrypt_next       // while (count != 0)
        jmp done               // decryption done
decrypt_next:                  // loop done, go to done
        jmp decrypt_loop       // go to next iteration

encrypt:
        // init encrypt
        lda #0
        sta SUM
        sta SUM+1
        sta SUM+2
        sta SUM+3
        lda #ROUNDS            // get rounds
        sta ROUND_COUNT        // init round counter
encrypt_loop:                  // encrypt multiple rounds

        // sum += DELTA
        clc
        lda SUM
        adc #DELTA0
        sta SUM
        lda SUM+1
        adc #DELTA1
        sta SUM+1
        lda SUM+2
        adc #DELTA2
        sta SUM+2
        lda SUM+3
        adc #DELTA3
        sta SUM+3

        // ======== PART ONE ========
        // v0 += ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        copy32(TMP0, V1)       // tmp0 = v1
        shl4_32(TMP0)          // tmp0 = v1 << 4
        add32(TMP0, K0)        // tmp0 = (v1 << 4) + k0
        copy32(TMP1, V1)       // tmp1 = v1
        add32(TMP1, SUM)       // tmp1 = v1 + sum
        xor32(TMP0, TMP1)      // tmp0 = ((v1 << 4) + k0) ^ (v1 + sum)
        copy32(TMP1, V1)       // tmp1 = v1
        shr5_32(TMP1)          // tmp1 = v1 >> 5
        add32(TMP1, K1)        // tmp1 = (v1 >> 5) + k1
        xor32(TMP0, TMP1)      // tmp0 = ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1)
        add32(V0, TMP0)        // v0 += tmp0

        // ======== PART TWO ========
        // v1 += ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
        copy32(TMP0, V0)       // tmp0 = v0
        shl4_32(TMP0)          // tmp0 = v0 << 4
        add32(TMP0, K2)        // tmp0 = (v0 << 4) + k2
        copy32(TMP1, V0)       // tmp1 = v0
        add32(TMP1, SUM)       // tmp1 = v0 + sum
        xor32(TMP0, TMP1)      // tmp0 = ((v0 << 4) + k2) ^ (v0 + sum)
        copy32(TMP1, V0)       // tmp1 = v0
        shr5_32(TMP1)          // tmp1 = v0 >> 5
        add32(TMP1, K3)        // tmp1 = (v0 >> 5) + k3
        xor32(TMP0, TMP1)      // tmp0 = ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3)
        add32(V1, TMP0)        // v1 += tmp0
        
        dec ROUND_COUNT        // count--
        bne encrypt_next       // while (count != 0)
        jmp done               // done encrypt
encrypt_next:
        jmp encrypt_loop       // go to next iteration

done:                          // finished, get back to BASIC
        jsr store_data         // store data for BASIC to access
        // print32(BAS_DATA)
        // print_cr()
        rts                    // return to BASIC

// ==========================================================
// Load / store
// ==========================================================

load_data:              // subroutine: Load data from BASIC
        ldx #0          // x = 0
load_loop:
        lda BAS_DATA, x // load data byte
        sta V0, x       // store to data area
        lda BAS_KEY, x  // load key byte
        sta K0, x       // store to key area
        inx             // x++
        cpx #8          // get first 8 bytes of each
        bne load_loop   // while x != 8

        ldx #8          // x = 8
load_loop2:
        lda BAS_KEY, x  // load rest of key
        sta K0, x       // store to key area
        inx             // x++
        cpx #16         // next 8 bytes of key
        bne load_loop2  // while x != 16
        rts             // end load_data subroutine

store_data:             // subroutine: store data back to BASIC
        ldx #0          // x = 0
store_loop:
        lda V0, x       // load processed byte
        sta BAS_DATA, x // store back to BASIC
        inx             // x++
        cpx #8          // 8 bytes (V0,V1)
        bne store_loop  // while x != 8
        rts             // end store_data subroutine

// ==========================================================
// Utils
// ==========================================================

print_hex_nibble:       // subroutine: print hex nibble to screen
    cmp #10             //
    bcc is_digit        // if < 10
    clc                 //
    adc #('A' - 10)     // num to hex ascii. ex: 10='A', 15='F'
    jmp print_digit     //
is_digit:               // handle 0-9
    clc                 //
    adc #'0'            // num to ascii. ex: 9 => '9'
print_digit:            //
    jsr CHROUT          // print char in A
    rts                 // end print_hex_nibble subroutine
