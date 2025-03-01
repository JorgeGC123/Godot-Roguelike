@echo off
echo Ejecutando tests...

REM Ubicación del ejecutable de Godot
SET GODOT_PATH=..\Godot_v3.6-stable_win64.exe
SET PROJECT_PATH=%cd%

REM Si se proporciona un argumento, ejecutar test específico
IF "%1"=="" (
    %GODOT_PATH% --path %PROJECT_PATH% --script TestRunner.gd
) ELSE (
    %GODOT_PATH% --path %PROJECT_PATH% --script TestRunner.gd --test=%1
)

echo.
echo Ejecución de tests finalizada.
