// Tiny Encryption Algorithm (TEA)

.encoding "petscii_upper"

.pc = $c000 "tea-subroutines" // entry point

// =================================
// Constants
// =================================

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

// =================================
// Top level
// =================================

start:                         // entry point
        jsr load_data          // load v0-v1, k0-k3 into zero page
        lda BAS_MODE           // load mode
        sta MODE               // store mode in zero page
        beq encrypt            // if mode=0, branch to encrypt

decrypt:                       // decrypt top level
        // init decrypt
        lda #DSUM0
        sta SUM
        lda #DSUM1
        sta SUM+1
        lda #DSUM2
        sta SUM+2
        lda #DSUM3
        sta SUM+3

        lda ROUNDS             // get rounds
        sta ROUND_COUNT        // init round counter
decrypt_loop:                  // decrypt multiple rounds
        
        // ======== PART ONE ========
        // v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        // TODO:

        // ======== PART TWO ========
        // v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        // TODO:
        
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
        bne decrypt_loop       // while (count != 0)
        jmp done               // done decryption

encrypt:                       // top level encrypt
        // init encrypt
        lda #0                 // a = 0
        sta SUM                // sum[0] = 0
        sta SUM+1              // sum[1] = 0
        sta SUM+2              // sum[2] = 0
        sta SUM+3              // sum[3] = 0

        ldx ROUNDS             // get rounds
        stx ROUND_COUNT        // init round counter
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
        // v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        // TODO:

        // ======== PART TWO ========
        // v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        // TODO:
        
        dec ROUND_COUNT        // count--
        bne encrypt_loop       // while (count != 0)

done:                          // finished, get back to BASIC
        jsr store_data         // store data for BASIC to access
        rts                    // return to BASIC

// =================================
// Load / store
// =================================

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

// =================================
// 32-bit operations
// =================================

add32:
    ldx #0
    clc
    lda TMP0
    adc TMP1
    sta TMP0
    lda TMP0+1
    adc TMP1+1
    sta TMP0+1
    lda TMP0+2
    adc TMP1+2
    sta TMP0+2
    lda TMP0+3
    adc TMP1+3
    sta TMP0+3
    rts
