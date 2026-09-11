# Gestione Certificati OpenSSL

Script batch per Windows con **menù guidato** che automatizza la generazione della chiave, la conversione dei certificati e l'export finale in `.p12`, pensato per l'utente finale alle prese con la procedura dei certificati dell'**Agenzia delle Dogane e dei Monopoli**.

## Perché esiste

Perché a un certo punto qualcuno all'Agenzia delle Dogane ha deciso che **impiegati amministrativi** — gente che lavora con Excel e la posta elettronica, non sistemisti — dovessero:

- aprire il **prompt dei comandi**;
- installare e usare **OpenSSL da riga di comando**;
- generare una chiave privata, produrre un CSR, **convertire il `.cer` in `.pem`** e poi il `.pem` in `.p12` con tre comandi diversi;
- indovinare quale dei file `.der` prodotti va caricato (spoiler: la richiesta, **non** la chiave privata);
- capire da soli in che ordine fare tutto.

E il capolavoro: il campo **Common Name (CN)** della richiesta **deve contenere la partita IVA**. Da nessuna parte è scritto prima. Lo scopri **dopo**, quando il portale rifiuta la richiesta con un errore specifico, lasciandoti a ricominciare da capo.

Aggiungici i comandi del PDF ufficiale con i trattini en-dash (`–`) copiaincollati che **fanno fallire OpenSSL**, e una chiave privata battezzata `key.der` che di DER non ha nulla. Il risultato è un impiegato che perde mezza giornata a bestemmiare per una cosa che sarebbe dovuta essere un click.

Questo script serve a trasformare quel calvario in un menù con sei voci. Prego, Agenzia. Di nulla.

## Il Common Name DEVE essere la partita IVA

Al passo 1, quando OpenSSL chiede i dati identificativi, il campo:

```
Common Name (e.g. server FQDN or YOUR name) []:
```

**va compilato con la partita IVA**, non con un nome, non con la ragione sociale, non con un dominio. Se sbagli qui, la generazione va a buon fine ma **il portale rifiuta la richiesta più avanti**, quando ormai hai già fatto tutti gli altri passaggi. Gli altri campi (paese, provincia, organizzazione, ecc.) puoi lasciarli vuoti con INVIO.

## Requisiti

- Windows
- OpenSSL per Windows installato. Lo script cerca l'eseguibile in:
  ```
  C:\Program Files\OpenSSL-Win64\bin\openssl.exe
  ```
  Se è altrove, modifica la variabile `OPENSSL` in cima al file `.bat`.

## Uso

1. Avvia `gestione_certificati.bat` (doppio click).
2. Segui il menù:
   - **1** — Genera chiave privata + richiesta (CSR) in formato `.der` (ricorda: CN = partita IVA)
   - **2** — Istruzioni per il portale (upload richiesta, "Richiedi Certificato", "Scarica Certificato")
   - **3** — Converti il `.cer` scaricato in `.pem`
   - **4** — Converti il `.pem` in `.p12` (file finale, **a questo va impostata la password**)
   - **5** — Procedura guidata completa passo-passo
   - **6** — Cambia cartella di lavoro
   - **0** — Esci

> Sul portale carichi la **richiesta** (`req.der`, il CSR), **non** la chiave privata (`key.der`). La chiave privata resta tua e non si carica da nessuna parte, mai.

## Le password: quali servono e quali no

Questo è l'altro punto dove il portale ti frega, quindi leggi bene:

| Passo | Prompt | Obbligatoria? |
|-------|--------|---------------|
| 1 — Generazione chiave | `PEM pass phrase` | **No.** Lo script usa `-noenc`: la chiave nasce senza passphrase e il prompt non compare. |
| 1 — Generazione richiesta | `challenge password` | **No.** Premi INVIO, è un campo opzionale dello standard, mai usato dalle CA. |
| 4 — Export `.p12` | `Export Password` | **SÌ. Obbligatoria.** |

**Il file `.p12` va convertito CON password.** Se lasci la password vuota al passo 4, il portale dell'Agenzia delle Dogane **rifiuta l'upload** senza spiegazioni utili. Quindi:

- Al passo **4** metti una password (annotala: ti servirà per importare/usare il certificato).
- In tutti gli altri passaggi la password è **facoltativa** e puoi ignorarla.

## Note tecniche

- Corretti i trattini `–` (en-dash) del PDF originale, sostituiti con `-`, altrimenti `openssl x509` va in errore.
- Se la tua versione di OpenSSL è molto vecchia e `-noenc` non è riconosciuto, sostituiscilo con `-nodes` nel `.bat`.

## License

Distribuito sotto licenza **GPL-3.0**. Vedi il testo completo della GNU General Public License v3.0: <https://www.gnu.org/licenses/gpl-3.0.html>.

## Author

<https://github.com/Leproide>
