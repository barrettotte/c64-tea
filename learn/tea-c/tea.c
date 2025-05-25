// Working through TEA to help port to 6502 assembly
// https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm
//
// gcc -o tea tea.c && ./tea

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define ROUNDS 32

#define DELTA     0x9E3779B9 // key schedule constant
#define DSUM_INIT 0xC6EF3720 // (DELTA << 5) & 0xFFFFFFFF

// print hex output 8 bytes
void print_hex_bytes(uint32_t v[2]) {
    uint8_t *bytes = (uint8_t*) v;
    for (int i = 0; i < 8; i++) {
        printf("%02X ", bytes[i]);
    }
    printf("\n");
}

// TEA encrypt
void encrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t sum = 0;
    uint32_t v0 = v[0], v1 = v[1];
    uint32_t vtmp0 = 0, vtmp1 = 0;
    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3]; // cache key

    for (uint32_t i = 0; i < ROUNDS; i++) {
        sum += DELTA;
        
        // part 1
        // v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        vtmp0 = v1;
        vtmp0 = vtmp0 << 4;
        vtmp0 = vtmp0 + k0;
        vtmp0 = vtmp0 ^ (v1 + sum);
        vtmp0 = vtmp0 ^ ((v1 >> 5) + k1);
        v0 += vtmp0;

        // part 2
        // v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        vtmp1 = v0;
        vtmp1 = vtmp1 << 4;
        vtmp1 = vtmp1 + k2;
        vtmp1 = vtmp1 ^ (v0 + sum);
        vtmp1 = vtmp1 ^ ((v0 >> 5) + k3);
        v1 += vtmp1;
    }
    v[0] = v0; 
    v[1] = v1;
}

// TEA decrypt
void decrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t sum = DSUM_INIT;
    uint32_t v0 = v[0], v1 = v[1];
    uint32_t vtmp0 = 0, vtmp1 = 0;
    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3]; // cache key

    for (uint32_t i = 0; i < ROUNDS; i++) {
        // part 1
        // v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        vtmp1 = v0 << 4;
        vtmp1 = vtmp1 + k2;
        vtmp1 = vtmp1 ^ (v0 + sum);
        vtmp1 = vtmp1 ^ ((v0 >> 5) + k3);
        v1 -= vtmp1;

        // part 2
        // v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        vtmp0 = v1 << 4;
        vtmp0 = vtmp0 + k0;
        vtmp0 = vtmp0 ^ (v1 + sum);
        vtmp0 = vtmp0 ^ ((v1 >> 5) + k1);
        v0 -= vtmp0;

        sum -= DELTA;
    }
    v[0] = v0;
    v[1] = v1;
}

// convert hex string to bytes
void hexstr_to_bytes(const char* hex, uint8_t* out) {
    // read 2 hex chars at a time, convert to uint8_t
    for (int i = 0; i < 8; i++) {
        sscanf(hex + 2 * i, "%2hhX", &out[i]);
    }
}

int main() {
    // ========================================
    // test encrypt message, then decrypt
    // ========================================

    const char* keyString = "0123456789ABCDEF";
    const char* message = "HELLO";

    // convert key string to 128-bit key (32 * 4)
    uint32_t key[4];
    memcpy(key, keyString, 16);

    // pad message to 8 bytes (64-bit) and convert to two 32-bit
    char block[8] = {0};
    strncpy(block, message, 8);
    uint32_t v[2];
    memcpy(v, block, 8);

    printf("Original message: %s\n", block);

    encrypt(v, key);
    printf("Encrypted hex:\n");
    print_hex_bytes(v); // 9C 69 1C 84 62 5A F8 B7

    decrypt(v, key);
    memcpy(block, v, 8);
    block[7] = '\0';
    printf("Decrypted message: %s\n", block);

    // ========================================
    // test decrypting from hex string input
    // ========================================

    const char* hexStr = "9C691C84625AF8B7"; // HELLO encrypted
    uint32_t v2[2];
    hexstr_to_bytes(hexStr, (uint8_t*) v2);

    printf("\nDecrypting hex: %s\n", hexStr);
    decrypt(v2, key);

    char out[9] = {0};
    memcpy(out, v2, 8);
    out[8] = '\0';
    printf("Decrypted hex: %s\n", out);

    return 0;
}
