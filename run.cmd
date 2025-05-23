@ECHO OFF
@REM Compile source and run in emulator

@REM Get repo directory based on this script's path
SET "REPO_DIR=%~dp0"
IF "%REPO_DIR:~-1%" == "\" SET "REPO_DIR=%REPO_DIR:~0,-1%"

SET VICE_DIR="D:\\programs\\GTK3VICE-3.9-win64\\bin"
SET "VICE_64SC=%VICE_DIR%\\x64sc.exe"
SET "VICE_PETCAT=%VICE_DIR%\\petcat.exe"
SET "VICE_CONFIG=%REPO_DIR%\\vice-config.ini"

SET "PRG=%REPO_DIR%\\tea.prg"

@REM Compile source to .pgm
@ECHO Compiling...
@REM java -jar %KICKASS% "%REPO_DIR%\\learn\\hello-asm\\hello.asm" -o %PRG% -showmem
%VICE_PETCAT% -w2 -o %PRG% -- "%REPO_DIR%\\learn\\hello-bas\\hello.bas"

IF %ERRORLEVEL% NEQ 0 ECHO Build failed & EXIT 1

@REM Launch VICE with .pgm loaded
@ECHO Launching emulator...
%VICE_64SC% -config %VICE_CONFIG% %PRG%

@REM SYS 49152
