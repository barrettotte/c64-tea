import os
import subprocess
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
BUILD_DIR = REPO_DIR / 'build'
SRC_DIR = REPO_DIR / 'learn' / 'hello-mixed'
OUTPUT_PRG = REPO_DIR / 'tea.prg'

KICKASS_JAR = Path('D:/programs/KickAssembler/kickass.jar')
VICE_DIR = Path('D:/programs/GTK3VICE-3.9-win64/bin')
VICE_64SC = VICE_DIR / 'x64sc.exe'
VICE_PETCAT = VICE_DIR / 'petcat.exe'
VICE_CONFIG = REPO_DIR / 'vice-config.ini'

def bas_to_prg(bas_file: Path) -> Path:
    '''Compile given .bas file to .bas.prg'''

    out = BUILD_DIR / (Path(bas_file).name + '.prg')
    print(f'Compiling {bas_file} to {out}')
    result = subprocess.run([str(VICE_PETCAT), '-w2', '-o', str(out), '--', str(bas_file)], capture_output=True, text=True)
    
    print(result.stdout)
    if result.returncode != 0:
        raise RuntimeError(f'BASIC compilation failed: {bas_file}\n{result.stderr}')
    return out

def asm_to_prg(asm_file: Path) -> Path:
    '''Compile given .asm file to .asm.prg'''

    out = BUILD_DIR / (Path(asm_file).name + '.prg')
    print(f'Compiling {asm_file} to {out}')
    result = subprocess.run(['java', '-jar', str(KICKASS_JAR), str(asm_file), '-o', str(out), '-showmem'], capture_output=True, text=True)
    
    print(result.stdout)
    if result.returncode != 0:
        raise RuntimeError(f'ASM compilation failed: {asm_file}\n{result.stderr}')
    return out

def combine_prg(prgs: list, out: Path):
    '''Combine all PRG files to single PRG with correct loading addresses'''

    memory = []
    for file in prgs:
        file = Path(file)
        if not file.exists():
            raise RuntimeError(f'File not found: {file}')

        data = file.read_bytes()
        load_addr = data[0] + (data[1] << 8)
        code = data[2:] # skip 2-byte load address

        memory.append((load_addr, code))
        print(f'Load address for {file} - 0x{load_addr:04X}, size: {len(code)} bytes')

    # sort by load address
    memory.sort(key=lambda x: x[0])

    combined = bytearray()
    curr_addr = memory[0][0]

    # add 2-byte load address
    combined.append(curr_addr & 0xFF)
    combined.append((curr_addr >> 8) & 0xFF)

    for addr, code in memory:
        if addr > curr_addr:
            pad = addr - curr_addr
            print(f'Padding {pad} bytes from 0x{curr_addr:04X} to 0x{addr:04X}')
            combined.extend(b'\x00' * pad)
        combined.extend(code)
        curr_addr = addr + len(code)

    out.write_bytes(combined)
    print(f'Combined PRG {len(combined)} byte(s) written to {out}')

def clean():
    print('Cleaning...')
    if os.path.exists(OUTPUT_PRG):
        os.remove(OUTPUT_PRG)
    for f in BUILD_DIR.glob('*.prg'):
        os.remove(f)

def main():
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    clean()

    # compile sources to PRG files
    prgs = []
    for bas in list((SRC_DIR).glob('*.bas')):
        prgs.append(bas_to_prg(bas))
    for asm in list((SRC_DIR).glob('*.asm')):
        prgs.append(asm_to_prg(asm))

    # build and run final PRG
    combine_prg(prgs, OUTPUT_PRG)
    print(f'Launching {OUTPUT_PRG} in VICE...')
    subprocess.run([str(VICE_64SC), '-config', str(VICE_CONFIG), str(OUTPUT_PRG)])

if __name__ == '__main__':
    main()
