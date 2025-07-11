# c64-tea

Tiny Encryption Algorithm (TEA) for Commodore 64 using BASIC and 6502 ASM.

I saw this was called "Tiny Encryption Algorithm" and wanted to test if it was "tiny" enough to run on a Commodore 64.
I also wanted to get practice with using machine code in BASIC programs and refresh on 6502 assembly.

The BASIC is just the user interface and the 6502 assembly is for all the heavy lifting for TEA.

Technically I could have compiled a C implementation to the 6502 architecture, but I like to mess around with
assembly when I get the chance and LARP as a 1980s developer.

## Running

`python build.py`

This does the following
- compiles `tea.bas` to `build/tea.bas.prg` using petcat
- compiles `tea.asm` to `build/tea.asm.prg` using kickassembler
- combines `tea.bas.prg` and `tea.asm.prg` into `tea.prg`
- launches VICE emulator with `tea.prg`

### Encryption

![./docs/encrypt.png](./docs/encrypt.png)

### Decryption

![./docs/decrypt.png](./docs/decrypt.png)

## Development

Install development dependencies:
- Windows
- Java 11+
- Python 3+
- https://theweb.dk/KickAssembler/Main.html#frontpage
- https://vice-emu.sourceforge.io/
- VS Code Extensions
  - 6502 Asm highlighting - https://marketplace.visualstudio.com/items?itemName=CaptainJiNX.kickass-c64
  - BASIC highlighting - https://marketplace.visualstudio.com/items?itemName=Tandy.color-basic

Examples of TEA in C and simple BASIC/ASM programs can be found in [./learn/](./learn/).

### Debug PRG Loading

```txt
# Verify PRGs loading correctly from D64

LOAD "TEABAS",8
LIST 10-50

LOAD "TEAASM",8,1
LIST 10-50

# monitor: verify assembly prg loaded correctly
m c000 c01f

# monitor: verify basic prg loaded correctly
m 0801 081f

# check BASIC pointers
#   $2B-$2C start of BASIC (01 08)
#   $2D-$2E start of vars (VARTAB), should point right after TEAMAIN
#   $2F-$30 start of arrays
#   $31-$32 end of arrays
m 2b 32
```

## References

- C64
  - https://github.com/spiroharvey/c64/blob/main/asm/C64%20Assembly%20Coding%20Guide.md
  - https://en.wikibooks.org/wiki/6502_Assembly
  - https://hackaday.com/2024/06/06/using-kick-assembler-and-vs-code-to-write-c64-assembler/
  - ["Hello World" on Commodore 64 in Assembly Language, Machine Code | 8-bit Show And Tell](https://www.youtube.com/watch?v=CHLzzfEmj3I)
  - [Use Kick Assembler and Visual Studio Code to write Commodore 64 Assembly Language | My Developer Thoughts](https://www.youtube.com/watch?v=gNC_A03zRbg)
  - [Writing Commodore 64 Assembly Language...using only BASIC | My Developer Thoughts](https://www.youtube.com/watch?v=H-n64TxS7MM)
  - https://pickledlight.blogspot.com/p/commodore-64-guides.html
  - https://theweb.dk/KickAssembler/KickAssembler.pdf
  - https://vice-emu.sourceforge.io/vice_toc.html
  - https://www.c64-wiki.com/wiki/Memory_Map
  - https://www.masswerk.at/6502/6502_instruction_set.html
- TEA
  - https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm
  - https://tayloredge.com/reference/Mathematics/TEA-XTEA.pdf
  - [Test Vectors for TEA and XTEA](https://www.cix.co.uk/~klockstone/teavect.htm)
  - [TEA, a Tiny Encryption Algorithm](./docs/tea-wheeler-needham.pdf)
