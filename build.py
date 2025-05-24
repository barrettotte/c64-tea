import os
import subprocess
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
BUILD_DIR = REPO_DIR / 'build'
# SRC_DIR = REPO_DIR / 'learn' / 'hello-mixed'
SRC_DIR = REPO_DIR
OUTPUT_PRG = REPO_DIR / 'tea.prg'

KICKASS_JAR = Path('D:/programs/KickAssembler/kickass.jar')
VICE_DIR = Path('D:/programs/GTK3VICE-3.9-win64/bin')
VICE_64SC = VICE_DIR / 'x64sc.exe'
VICE_PETCAT = VICE_DIR / 'petcat.exe'
VICE_CONFIG = REPO_DIR / 'vice-config.ini'
VICE_C1541 = VICE_DIR / 'c1541.exe'

def bas_to_prg(bas_file: Path) -> Path:
    '''Compile given .bas file to .bas.prg'''

    out = BUILD_DIR / (Path(bas_file).name + '.prg')
    print(f'Compiling {bas_file} to {out}')

    # convert source to lowercase to avoid PETSCII issues and remove blank lines
    tmp_path = BUILD_DIR / Path(f'{bas_file.stem}-clean.bas')
    with open(bas_file, 'r') as f:
        cleaned = [line.lower() for line in f.readlines() if line.strip() != '']
        with open(tmp_path, 'w+', encoding='utf-8') as tmp_f:
            tmp_f.writelines(cleaned)
    
    args = [str(VICE_PETCAT), '-w2', '-o', str(out), '--', str(tmp_path)]
    print(f"petcat command: {' '.join(args)}")
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    
    if result.stdout:
        print(f"petcat stdout:\n{result.stdout}")
    if result.stderr:
        print(f"petcat stderr:\n{result.stderr}")
    if result.returncode != 0 or not out.exists() or out.stat().st_size == 0:
        raise RuntimeError(f'BASIC compilation failed for: {bas_file}\nError: {result.stderr or result.stdout}')

    print(f'Successfully compiled {bas_file} to {out}')
    return out

def asm_to_prg(asm_file: Path) -> Path:
    '''Compile given .asm file to .asm.prg'''

    out = BUILD_DIR / (Path(asm_file).name + '.prg')
    print(f'Compiling {asm_file} to {out}')

    args = ['java', '-jar', str(KICKASS_JAR), str(asm_file), '-o', str(out), '-showmem']
    print(f"kickassembler command: {' '.join(args)}")
    result = subprocess.run(args, capture_output=True, text=True, check=False)

    if result.stdout:
        print(f"KickAssembler stdout:\n{result.stdout}")
    if result.stderr:
        print(f"KickAssembler stderr:\n{result.stderr}")
    if result.returncode != 0 or not out.exists() or out.stat().st_size == 0:
        raise RuntimeError(f'ASM compilation failed for: {asm_file}\nError: {result.stderr or result.stdout}')

    print(f'Successfully compiled {asm_file} to {out}')
    return out

def create_d64(d64_file: Path, disk_name: str, disk_id: str):
    """Create .d64 file for putting .prg files into"""

    args = [str(VICE_C1541), '-format', f'{disk_name},{disk_id}', 'd64', d64_file]
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    if result.stdout:
        print(f"C1541 stdout:\n{result.stdout}")
    if result.stderr:
        print(f"C1541 stderr:\n{result.stderr}")
    if result.returncode != 0 or not d64_file.exists() or d64_file.stat().st_size == 0:
        raise RuntimeError(f'D64 creation failed for: {d64_file}\nError: {result.stderr or result.stdout}')

def write_d64(d64_file: Path, prgs: list):
    """Write .prg files to .d64"""

    args = [str(VICE_C1541), str(d64_file),]
    for prg in prgs:
        args += ['-write', prg[0], prg[1].lower()]
    result = subprocess.run(args, capture_output=True, text=True, check=False)

    if result.stdout:
        print(f"C1541 stdout:\n{result.stdout}")
    if result.stderr:
        print(f"C1541 stderr:\n{result.stderr}")

def list_d64(d64_file: Path):
    """List files in .d64 file"""

    args = [str(VICE_C1541), str(d64_file), '-list']
    result = subprocess.run(args, capture_output=True, text=True, check=False)

    if result.stdout:
        print(f"C1541 stdout:\n{result.stdout}")
    if result.stderr:
        print(f"C1541 stderr:\n{result.stderr}")
    if result.returncode != 0:
        raise RuntimeError(f'D64 listing failed for: {d64_file}\nError: {result.stderr or result.stdout}')

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
    for f in BUILD_DIR.glob('*'):
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
    
    vice_args = [str(VICE_64SC), '-config', str(VICE_CONFIG)]
    USE_D64 = False

    if USE_D64:
        prgs = [
            (BUILD_DIR / 'tea.bas.prg', 'TEABAS'),
            (BUILD_DIR / 'tea.asm.prg', 'TEAASM')
        ]
        d64 = BUILD_DIR / 'tea.d64'
        create_d64(d64, 'tea', '01')
        write_d64(d64, prgs)
        list_d64(d64)
        vice_args += ['-8', str(d64)]
    else:
        # single prg approach
        combine_prg(prgs, OUTPUT_PRG)
        print(f'Launching {OUTPUT_PRG} in VICE...')
        vice_args.append(str(OUTPUT_PRG))

    try:
        print(f"VICE command: {' '.join(vice_args)}")
        subprocess.run(vice_args, check=True)

    except subprocess.CalledProcessError as e:
        print(f"Error launching VICE: {e}")
    except KeyboardInterrupt:
        print('Exited VICE via console')

if __name__ == '__main__':
    main()
