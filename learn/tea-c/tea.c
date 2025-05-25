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

void encrypt_message(const char* message, const uint32_t key[4], uint8_t** out, size_t* out_len) {
    size_t msg_len = strlen(message);
    size_t blocks = (msg_len + 7) / 8;  // round up to next multiple of 8
    size_t padded_len = blocks * 8;

    uint8_t* encrypted = malloc(padded_len);
    memset(encrypted, 0, padded_len);  // pad with 0s

    for (size_t i = 0; i < blocks; i++) {
        uint32_t v[2] = {0, 0};
        memcpy(&v, message + i * 8, msg_len - i * 8 >= 8 ? 8 : msg_len - i * 8);
        encrypt(v, key);
        memcpy(encrypted + i * 8, v, 8);
    }

    *out = encrypted;
    *out_len = padded_len;
}

void decrypt_message(const uint8_t* ciphertext, size_t length, const uint32_t key[4], char** out) {
    size_t blocks = length / 8;
    char* decrypted = malloc(length + 1);  // +1 for null terminator
    memset(decrypted, 0, length + 1);

    for (size_t i = 0; i < blocks; i++) {
        uint32_t v[2];
        memcpy(&v, ciphertext + i * 8, 8);
        decrypt(v, key);
        memcpy(decrypted + i * 8, &v, 8);
    }

    decrypted[length] = '\0';
    *out = decrypted;
}

// convert hex string to bytes
void hexstr_to_bytes(const char* hex, uint8_t* out) {
    // read 2 hex chars at a time, convert to uint8_t
    for (int i = 0; i < 8; i++) {
        sscanf(hex + 2 * i, "%2hhX", &out[i]);
    }
}

// convert bytes to hex string
char* bytes_to_hexstr(const uint8_t* bytes, size_t len) {
    if (len == 0) {
        return NULL;
    }
    // 3 chars per byte: 2 for hex, 1 for space, -1 for no space after last byte
    char* hexstr = malloc(len * 3);  // len * 2 + (len - 1) + 1 for null terminator
    if (!hexstr) {
        return NULL;
    }
    for (size_t i = 0; i < len; i++) {
        if (i < len - 1) {
            sprintf(hexstr + i * 3, "%02X ", bytes[i]);
        } else {
            sprintf(hexstr + i * 3, "%02X", bytes[i]);
        }
    }
    return hexstr;
}

int main() {
    // ========================================
    // test encrypt message, then decrypt
    // ========================================

    const char* keyString = "0123456789ABCDEF";
    const char* message = "HELLO WORLD";

    // convert key string to 128-bit key (32 * 4)
    uint32_t key[4];
    memcpy(key, keyString, 16);

    printf("Original message: %s\n", message);

    uint8_t* encrypted = NULL;
    size_t encrypted_len = 0;
    encrypt_message(message, key, &encrypted, &encrypted_len);

    printf("Encrypted hex:\n");
    for (size_t i = 0; i < encrypted_len; i++) {
        printf("%02X ", encrypted[i]);
    }
    printf("\n");

    char* decrypted = NULL;
    decrypt_message(encrypted, encrypted_len, key, &decrypted);
    printf("Decrypted message: %s\n", decrypted);

    free(encrypted);
    free(decrypted);

    // ========================================
    // test decrypting from hex string input
    // ========================================

    const char* hexStr = "0808EB296B8B7A4BFC2D02629C4F1E82"; // "HELLO WORLD" encrypted
    size_t hexLen = strlen(hexStr);
    size_t byteLen = hexLen / 2;

    uint8_t* encryptedHex = malloc(byteLen);
    for (size_t i = 0; i < byteLen; i++) {
        sscanf(hexStr + 2 * i, "%2hhX", &encryptedHex[i]);
    }

    printf("\nDecrypting hex: %s\n", hexStr);

    // Decrypt the message using helper
    char* decryptedHex = NULL;
    decrypt_message(encryptedHex, byteLen, key, &decryptedHex);
    printf("Decrypted: %s\n", decryptedHex);

    char* hexOut = bytes_to_hexstr((uint8_t*) decryptedHex, encrypted_len);
    printf("Decrypted as hex: %s\n", hexOut);

    free(encryptedHex);
    free(decryptedHex);

    return 0;
}
