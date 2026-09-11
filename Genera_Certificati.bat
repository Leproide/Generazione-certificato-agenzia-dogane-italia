@echo off
REM ============================================================
REM  Gestione Certificati OpenSSL - Menu guidato
REM
REM  License: GPL-3.0
REM  Author: https://github.com/Leproide
REM
REM  Questo programma e' software libero: puoi ridistribuirlo
REM  e/o modificarlo nei termini della GNU General Public License
REM  versione 3, come pubblicata dalla Free Software Foundation.
REM ============================================================

setlocal EnableDelayedExpansion
chcp 65001 >nul
title Gestione Certificati OpenSSL

REM --- Percorso fisso di OpenSSL ------------------------------
set "OPENSSL=C:\Program Files\OpenSSL-Win64\bin\openssl.exe"

REM --- Verifica presenza dell'eseguibile OpenSSL -------------
if not exist "%OPENSSL%" (
    echo.
    echo [ERRORE] OpenSSL non trovato in:
    echo     %OPENSSL%
    echo Verifica il percorso di installazione e correggi la variabile
    echo OPENSSL all'inizio di questo script, poi riprova.
    echo.
    pause
    exit /b 1
)

REM --- Cartella di lavoro (default: cartella dello script) ---
set "WORKDIR=%~dp0"
pushd "%WORKDIR%"

REM --- Valori predefiniti dei nomi file ----------------------
set "KEYFILE=key.der"
set "REQFILE=req.der"
set "CERFILE=cert.cer"
set "PEMFILE=cert.pem"
set "P12FILE=cert.p12"

:menu
cls
echo ============================================================
echo            GESTIONE CERTIFICATI - MENU
echo ============================================================
echo  OpenSSL : %OPENSSL%
echo  Cartella: %CD%
echo ------------------------------------------------------------
echo   1^) Genera chiave privata + richiesta (.der)
echo   2^) Istruzioni portale (carica richiesta / scarica .cer)
echo   3^) Converti .cer scaricato in .pem
echo   4^) Converti .pem in .p12 (file finale)
echo   5^) Procedura guidata completa (passo-passo)
echo   6^) Cambia cartella di lavoro
echo   0^) Esci
echo ============================================================
set /p "SCELTA=Scelta: "

if "%SCELTA%"=="1" goto step_key
if "%SCELTA%"=="2" goto step_portal
if "%SCELTA%"=="3" goto step_pem
if "%SCELTA%"=="4" goto step_p12
if "%SCELTA%"=="5" goto step_all
if "%SCELTA%"=="6" goto change_dir
if "%SCELTA%"=="0" goto fine
echo Scelta non valida.
timeout /t 2 >nul
goto menu

REM ============================================================
REM  1) Genera chiave privata + richiesta (CSR) in formato DER
REM ============================================================
:step_key
cls
echo --- GENERAZIONE CHIAVE + RICHIESTA -------------------------
set /p "KEYFILE=Nome file chiave privata [%KEYFILE%]: " || rem
if "%KEYFILE%"=="" set "KEYFILE=key.der"
set /p "REQFILE=Nome file richiesta (CSR) [%REQFILE%]: " || rem
if "%REQFILE%"=="" set "REQFILE=req.der"
echo.
echo Verranno richiesti i dati identificativi (paese, organizzazione, ecc.).
echo Premi INVIO su un campo per lasciarlo vuoto.
echo La chiave viene generata SENZA passphrase (nessun prompt password).
echo.
pause
REM -noenc: chiave privata non cifrata, evita il prompt "PEM pass phrase"
"%OPENSSL%" req -newkey rsa:2048 -noenc -keyout "%KEYFILE%" -out "%REQFILE%" -outform DER
if errorlevel 1 (
    echo.
    echo [ERRORE] Generazione non riuscita.
) else (
    echo.
    echo [OK] Creati:
    echo     - Chiave privata : %CD%\%KEYFILE%   ^(DA CUSTODIRE, NON caricare^)
    echo     - Richiesta CSR  : %CD%\%REQFILE%   ^(questo file va caricato sul portale^)
)
echo.
pause
goto menu

REM ============================================================
REM  2) Istruzioni per il portale (passi manuali)
REM ============================================================
:step_portal
cls
echo --- ISTRUZIONI PORTALE -------------------------------------
echo.
echo  1. Accedi al portale.
echo  2. Carica il file di RICHIESTA: %REQFILE%
echo     ^(la richiesta CSR, NON la chiave privata %KEYFILE%^).
echo  3. Premi il pulsante "Richiedi Certificato"
echo     ^(compare solo dopo aver caricato il file^).
echo  4. Attendi pochi secondi la preparazione del certificato.
echo  5. Premi "Scarica Certificato" e salva il file .cer
echo     in questa cartella: %CD%
echo.
echo  Suggerimento: annota il nome del .cer scaricato,
echo  ti servira' al punto 3 del menu.
echo.
pause
goto menu

REM ============================================================
REM  3) Conversione .cer -> .pem
REM ============================================================
:step_pem
cls
echo --- CONVERSIONE .cer in .pem -------------------------------
set /p "CERFILE=Nome file .cer scaricato [%CERFILE%]: " || rem
if "%CERFILE%"=="" set "CERFILE=cert.cer"
if not exist "%CERFILE%" (
    echo [ERRORE] File "%CERFILE%" non trovato in %CD%.
    echo.
    pause
    goto menu
)
set /p "PEMFILE=Nome file .pem in uscita [%PEMFILE%]: " || rem
if "%PEMFILE%"=="" set "PEMFILE=cert.pem"
"%OPENSSL%" x509 -inform der -in "%CERFILE%" -out "%PEMFILE%"
if errorlevel 1 (
    echo.
    echo [ERRORE] Conversione non riuscita.
) else (
    echo.
    echo [OK] Creato: %CD%\%PEMFILE%
)
echo.
pause
goto menu

REM ============================================================
REM  4) Conversione .pem -> .p12 (richiede la chiave privata)
REM ============================================================
:step_p12
cls
echo --- CONVERSIONE .pem in .p12 -------------------------------
set /p "KEYFILE=Nome file chiave privata [%KEYFILE%]: " || rem
if "%KEYFILE%"=="" set "KEYFILE=key.der"
if not exist "%KEYFILE%" (
    echo [ERRORE] Chiave "%KEYFILE%" non trovata in %CD%.
    echo.
    pause
    goto menu
)
set /p "PEMFILE=Nome file .pem [%PEMFILE%]: " || rem
if "%PEMFILE%"=="" set "PEMFILE=cert.pem"
if not exist "%PEMFILE%" (
    echo [ERRORE] File "%PEMFILE%" non trovato in %CD%.
    echo.
    pause
    goto menu
)
set /p "P12FILE=Nome file .p12 in uscita [%P12FILE%]: " || rem
if "%P12FILE%"=="" set "P12FILE=cert.p12"
echo.
echo Verra' chiesta una password di esportazione per il file .p12.
echo Annotala: servira' per importare il certificato.
echo.
"%OPENSSL%" pkcs12 -export -inkey "%KEYFILE%" -in "%PEMFILE%" -out "%P12FILE%"
if errorlevel 1 (
    echo.
    echo [ERRORE] Conversione non riuscita.
) else (
    echo.
    echo [OK] File finale creato: %CD%\%P12FILE%
)
echo.
pause
goto menu

REM ============================================================
REM  5) Procedura guidata completa
REM ============================================================
:step_all
call :step_key
call :step_portal
echo Quando hai scaricato il file .cer, premi un tasto per continuare.
pause
call :step_pem
call :step_p12
echo.
echo Procedura completata.
pause
goto menu

REM ============================================================
REM  6) Cambia cartella di lavoro
REM ============================================================
:change_dir
cls
set /p "NEWDIR=Percorso nuova cartella di lavoro: "
if exist "%NEWDIR%\" (
    popd
    pushd "%NEWDIR%"
    echo [OK] Cartella impostata: %CD%
) else (
    echo [ERRORE] Cartella non valida.
)
echo.
pause
goto menu

:fine
popd
endlocal
exit /b 0
