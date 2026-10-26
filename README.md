# HAS-BeamMP

## English
Hide and Seek (HAS) is a multiplayer game mode for BeamMP inspired by classic hide-and-seek. At the start of each round, one player is randomly chosen as the seeker while the others get time to hide. Once the hiding period ends, the seeker searches for the hiders and catches them by colliding with their vehicles; caught players join the seeking team. Hiders win by surviving until time runs out, while the seekers win by finding everyone. The mode includes in-game announcements, a round timer, role-based visual effects, and rules to limit vehicle recovery and switching exploits.

### Installation
1. Copy `Server\HAS` to the BeamMP server's `Resources\Server` directory.
2. Package the contents of `Client` as `HAS.zip` and place it in `Resources\Client`.
3. Restart the server and clients, then use `/has help` in chat.

   The resource uses BeamMP's Lua events and BeamNG's GE/vehicle Lua extensions, input action filters, HUD hooks, and PostEffect shader pipeline.

### Commands
- `/has start` - starts a round with all eligible connected players who have a vehicle.
- `/has stop` - stops the active round and restores client effects.
- `/has language pl` or `/has language en` - sets the language for game announcements and HUD text.
- `/has settings round <seconds>` - sets round duration (default: 300 seconds).
- `/has settings hide <seconds>` - sets hiding time (default: 30 seconds).
- `/has settings countdown <seconds>` - sets the initial immobilization countdown (default: 5 seconds).
- `/has settings pulse on|off` - toggles the seekers' blue/original color pulse (disabled by default).
- `/has help` - displays this command list in the server's current language.

### Round flow

The selected seeker is announced at the start of the countdown. During the countdown, vehicle controls are locked without altering vehicle physics. After the countdown, nicknames are hidden, and the seeker remains blurred and immobilized during hiding time. Hiders can drive away. When hiding time expires, the seeker and any caught players can drive; a vehicle collision with a hider catches them and adds them to the seeking team. Players who lose their vehicle can recover or reload it. Hiders win when round time expires; seekers win when all players have been found. Vehicle colors, nicknames, blur, and input filters are restored at the end or when the client extension unloads.

During a round, client-side input filters block participants from switching camera views or opening the vehicle selector; attempts to switch vehicles are reverted. This does not prevent a modified client from bypassing the restrictions. Seekers can recover their vehicle at any time. Hiders can recover theirs after it has remained stationary for 10 seconds; the HUD shows the remaining wait and when recovery is available. Teleport and global reset actions stay blocked.

## Polski

Hide and Seek (HAS) to tryb multiplayer do BeamMP inspirowany klasyczną zabawą w chowanego. Na początku każdej rundy losowany jest szukający, a pozostali gracze dostają czas na ukrycie się. Po jego upływie szukający rusza na poszukiwania i łapie chowających przez zderzenie ich pojazdów; złapani gracze dołączają do szukających. Chowający wygrywają, jeśli przetrwają do końca czasu, a szukający — jeśli odnajdą wszystkich. Tryb oferuje komunikaty w grze, licznik rundy, efekty wizualne zależne od roli oraz ograniczenia utrudniające nadużywanie odzyskiwania i zmiany pojazdów.

### Instalacja

1. Skopiuj folder `Server\HAS` do folderu `Resources\Server` na serwerze BeamMP.
2. Spakuj zawartość folderu `Client` do archiwum `HAS.zip` i umieść je w folderze `Resources\Client`.
3. Uruchom ponownie serwer BeamMP i grę BeamNG u graczy. Następnie wpisz `/has help` na czacie w grze, aby wyświetlić listę komend.

   Zasób korzysta ze zdarzeń Lua BeamMP oraz rozszerzeń GE i pojazdów BeamNG, filtrów akcji wejściowych, elementów HUD i potoku shaderów PostEffect.

### Komendy

- `/has start` — rozpoczyna rundę z połączonymi graczami, którzy mają pojazd.
- `/has stop` — zatrzymuje trwającą rundę i przywraca efekty po stronie klienta.
- `/has language pl` lub `/has language en` — ustawia język komunikatów i HUD-u.
- `/has settings round <sekundy>` — ustawia czas trwania rundy (domyślnie: 300 sekund).
- `/has settings hide <sekundy>` — ustawia czas na schowanie się (domyślnie: 30 sekund).
- `/has settings countdown <sekundy>` — ustawia początkowy czas unieruchomienia (domyślnie: 5 sekund).
- `/has settings pulse on|off` — włącza lub wyłącza pulsowanie niebieskiego i oryginalnego koloru pojazdów szukających (domyślnie wyłączone).
- `/has help` — wyświetla listę komend w aktualnie ustawionym języku.

### Przebieg rundy

Wylosowany szukający zostaje ogłoszony na początku odliczania. W tym czasie sterowanie pojazdem jest zablokowane, ale jego fizyka nie ulega zmianie. Po odliczaniu nicki graczy zostają ukryte, a szukający jest rozmyty i unieruchomiony na czas chowania. Chowający mogą odjechać i znaleźć kryjówkę. Po upływie czasu na chowanie szukający oraz złapani gracze mogą ruszyć; zderzenie pojazdu szukającego z chowającym łapie go i dołącza do drużyny szukających. Gracze, którzy stracą pojazd, mogą go odzyskać lub ponownie wczytać. Chowający wygrywają, jeśli czas rundy minie, a szukający — jeśli odnajdą wszystkich. Po zakończeniu rundy lub wyładowaniu rozszerzenia klienta przywracane są kolory pojazdów, widoczność nicków, efekt rozmycia i filtry akcji.

Podczas rundy filtry akcji po stronie klienta blokują uczestnikom zmianę widoku kamery i otwarcie selektora pojazdów; próba zmiany pojazdu jest cofana. Zmodyfikowany klient może ominąć te ograniczenia. Szukający mogą odzyskać pojazd w dowolnym momencie. Chowający mogą go odzyskać, gdy ich pojazd pozostawał nieruchomy przez 10 sekund; HUD pokazuje pozostały czas oczekiwania i informuje, kiedy odzyskiwanie jest dostępne. Teleportacja i globalne resetowanie pozostają zablokowane.

***UWAGA!!!*** ***NIE WSZYSTKIE FUNKCJĘ DZIAŁAJĄ***
