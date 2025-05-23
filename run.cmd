@ECHO OFF
@REM Compile source and run in emulator

SET REPO_DIR="%CD%"

SET KICKASS="D:/programs/KickAssembler/kickass.jar"

SET VICE_64SC="D:/programs/GTK3VICE-3.9-win64/bin/x64sc.exe"
SET VICE_CONFIG="%REPO_DIR%/vice-config.ini"

SET PRG="%REPO_DIR%/tea.prg"

@REM Compile source to .pgm
java -jar %KICKASS% "%REPO_DIR%/learn/hello-asm/hello.asm" -o %PRG% -showmem

IF %ERRORLEVEL% NEQ 0 ECHO Build failed & EXIT 1

@REM Launch VICE with .pgm loaded
%VICE_64SC% -config %VICE_CONFIG% %PRG%

@REM SYS 49152
