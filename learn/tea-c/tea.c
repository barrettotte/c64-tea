// C test program for understanding TEA
// gcc -o tea tea.c

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define DELTA 0x9E3779B9 // key schedule number -> 2^(32)/phi, where phi is golden ratio
#define TEA_ROUNDS 32

// TEA encrypt block of data using given key.
void encrypt(uint32_t v[2], const uint32_t k[4]) {
    uint32_t sum = 0;
    for (int i = 0; i < TEA_ROUNDS; i++) {
        sum += DELTA;
        v[0] += ((v[1] << 4 ^ v[1] >> 5) + v[1]) ^ (sum + k[sum & 3]);
        v[1] += ((v[0] << 4 ^ v[0] >> 5) + v[0]) ^ (sum + k[(sum >> 11) & 3]);
    }
}

// TEA decrypt block of data using given key.
void decrypt(uint32_t v[2], const uint32_t k[4]) {
    uint32_t sum = DELTA * TEA_ROUNDS;
    for (int i = 0; i < TEA_ROUNDS; i++) {
        v[1] -= ((v[0] << 4 ^ v[0] >> 5) + v[0]) ^ (sum + k[(sum >> 11) & 3]);
        v[0] -= ((v[1] << 4 ^ v[1] >> 5) + v[1]) ^ (sum + k[sum & 3]);
        sum -= DELTA;
    }
}

// Pad string to multiple of 8 bytes
size_t pad(uint8_t* dest, const char* src) {
    size_t len = strlen(src);
    size_t pad_len = ((len + 7) / 8) * 8;
    memcpy(dest, src, len);

    for (size_t i = len; i < pad_len; i++) {
        dest[i] = 0; // zero pad
    }
    return pad_len;
}

// Parse 32 char hex string to 128-bit key
int parse_key(const char* hex, uint32_t key[4]) {
    if (strlen(hex) != 32) {
        return 0;
    }
    for (int i = 0; i < 4; i++) {
        char chunk[9] = {0};
        memcpy(chunk, &hex[i * 8], 8);

        if (strspn(chunk, "0123456789ABCDEFabcdef") != 8) {
            return 0;
        }
        key[i] = (uint32_t) strtoul(chunk, NULL, 16);
    }
    return 1;
}

// flush any extra data in stdin
void flush_stdin() {
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

int main() {
    char key_hex[33]; // ex: A56BABCD00000000FFFFFFFF12345678
    uint32_t key[4];
    char input[256];
    uint8_t buffer[256], decrypted[256];
    uint32_t v[2];

    // get encryption key

    printf("Enter 128-bit key as 32 hex digits (without leading 0x): ");
    if (!fgets(key_hex, sizeof(key_hex), stdin)) {
        fprintf(stderr, "Failed to read key.\n");
        return 1;
    }
    
    key_hex[strcspn(key_hex, "\n")] = '\0';
    flush_stdin();
    if (!parse_key(key_hex, key)) {
        fprintf(stderr, "Invalid key. Must be 32 hex digits.\n");
        return 1;
    }

    // get string to encrypt/decrypt

    printf("Enter string to encrypt (max 255 chars): ");
    if (!fgets(input, sizeof(input), stdin)) {
        fprintf(stderr, "Error reading input.\n");
        return 1;
    }

    input[strcspn(input, "\n")] = '\0';
    size_t len = pad(buffer, input);

    printf("Padded byte(s):\n    ");
    for (size_t i = 0; i < len; i++) {
        printf("%02X ", buffer[i]);
        if ((i + 1) % 8 == 0) {
            printf("\n    ");
        }
    }
    printf("\n");

    printf("Encrypted block(s):\n");
    for (size_t i = 0; i < len; i += 8) {
        memcpy(&v[0], &buffer[i], 4);
        memcpy(&v[1], &buffer[i + 4], 4);
        encrypt(v, key);

        memcpy(&buffer[i], &v[0], 4);
        memcpy(&buffer[i + 4], &v[1], 4);
        printf("    %08X %08X\n", v[0], v[1]);
    }
    printf("\n");

    for (size_t i = 0; i < len; i += 8) {
        memcpy(&v[0], &buffer[i], 4);
        memcpy(&v[1], &buffer[i + 4], 4);
        decrypt(v, key);

        memcpy(&decrypted[i], &v[0], 4);
        memcpy(&decrypted[i + 4], &v[1], 4);
    }
    decrypted[len] = '\0';
    printf("Decrypted: %s\n", decrypted);

    return 0;
}
