# HAS Installation / Instalacja HAS

## English

The installers are published in the [Instaler release](https://github.com/MrDemorok/HAS-BeamMP/releases/tag/Instaler). They download the latest HAS files from the public `main` branch and install:

- Server resource: `Resources/Server/HAS`
- Client resource: `Resources/Client/HAS.zip`

The client archive contains the files inside `Client` directly, without an extra top-level `Client` folder.

### Windows

1. Download `Install-HAS.cmd` from the [Instaler release](https://github.com/MrDemorok/HAS-BeamMP/releases/tag/Instaler).
2. Double-click `Install-HAS.cmd`. It downloads and runs the PowerShell installer automatically.
3. Enter the BeamMP server directory (the folder containing `Resources`) or the full path to `BeamMP-Server.exe`.
4. Wait for the success message.

Windows PowerShell, which is included with Windows, is required.
The `Instaler` release must include `Install-HAS.ps1` as a downloadable asset; `Install-HAS.cmd` downloads it from that release.

### Linux

1. Download `Install-HAS.sh`.
2. Open a terminal in the folder containing the script and run:

   ```bash
   chmod +x Install-HAS.sh
   ./Install-HAS.sh
   ```

3. Enter the BeamMP server directory (the folder containing `Resources`) or the full path to the server executable.
4. Wait for the success message.

The installer requires `curl`, `find`, and Python 3. Python's standard library is used to extract the download and create the client ZIP.

### After installation

Restart the BeamMP server and the players' BeamNG games. Then type `/has help` in chat to see the available commands.

The installer overwrites HAS files with matching names but does not remove other files from `Resources/Server/HAS`.

## Polski

Instalatory są udostępniane w [wydaniu Instaler](https://github.com/MrDemorok/HAS-BeamMP/releases/tag/Instaler). Pobierają najnowsze pliki HAS z publicznej gałęzi `main` i instalują:

- zasób serwera: `Resources/Server/HAS`
- zasób klienta: `Resources/Client/HAS.zip`

Archiwum klienta zawiera bezpośrednio pliki z folderu `Client`, bez dodatkowego folderu `Client` na najwyższym poziomie ZIP-a.

### Windows

1. Pobierz plik `Install-HAS.cmd` z [wydania Instaler](https://github.com/MrDemorok/HAS-BeamMP/releases/tag/Instaler).
2. Kliknij dwukrotnie `Install-HAS.cmd`. Automatycznie pobierze i uruchomi instalator PowerShell.
3. Podaj katalog serwera BeamMP (folder zawierający `Resources`) albo pełną ścieżkę do `BeamMP-Server.exe`.
4. Poczekaj na komunikat o pomyślnym zakończeniu instalacji.

Wymagany jest Windows PowerShell, który jest dołączony do systemu Windows.
W wydaniu `Instaler` musi być dodany plik `Install-HAS.ps1` jako załącznik do pobrania; `Install-HAS.cmd` pobiera go z tego wydania.

### Linux

1. Pobierz plik `Install-HAS.sh`.
2. Otwórz terminal w folderze ze skryptem i uruchom:

   ```bash
   chmod +x Install-HAS.sh
   ./Install-HAS.sh
   ```

3. Podaj katalog serwera BeamMP (folder zawierający `Resources`) albo pełną ścieżkę do pliku wykonywalnego serwera.
4. Poczekaj na komunikat o pomyślnym zakończeniu instalacji.

Instalator wymaga `curl`, `find` i Pythona 3. Do rozpakowania pobranej paczki i utworzenia ZIP-a klienta wykorzystuje standardową bibliotekę Pythona.

### Po instalacji

Uruchom ponownie serwer BeamMP i grę BeamNG u graczy. Następnie wpisz `/has help` na czacie, aby wyświetlić dostępne komendy.

Instalator nadpisuje pliki HAS o tych samych nazwach, ale nie usuwa innych plików z `Resources/Server/HAS`.
