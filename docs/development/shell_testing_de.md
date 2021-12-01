# Shell-Tests

Sie können Bash-Tests im Verzeichnis `unitTests` erstellen und ändern. Das Make-Target `unit-test-shell` unterstützt dabei mit einer verallgemeinerten Bash-Testumgebung.

```bash
make unit-test-shell
```

Um testbare Shell-Skripte zu schreiben, sollten diese Aspekte beachtet werden:

## Globale Umgebungsvariable `STARTUP_DIR`

Die globale Umgebungsvariable `STARTUP_DIR` zeigt auf das Verzeichnis, in dem sich die Produktionsskripte (auch bekannt als "script-under-test") befinden. Innerhalb des dogu-Containers ist dies normalerweise `/`. Aber während des Testens ist es einfacher, es aus Gründen der Berechtigung an einen anderen Ort zu legen.

Ein zweiter Grund ist, dass die Skripte, die getestet werden, andere Skripte aufrufen. Absolute Pfade machen das Testen ziemlich schwer. Sourcen Sie neue Skripte wie folgt, damit die Tests reibungslos ablaufen können:

```bash
source "${STARTUP_DIR}"/util.sh
```

Bitte beachten Sie im obigen Beispiel den Kommentar zur Deaktivierung von Shellcheck. Da `STARTUP_DIR` im `Dockerfile` verdrahtet ist, wird es als globale Umgebungsvariable betrachtet, die niemals ungesetzt gefunden werden wird (was bald zu Fehlern führen würde).

Wenn man Skripte auf statische Art und Weise bezieht (d.h. ohne dynamische Variable im Pfad), wird das Testen der Shell unmöglich (es sei denn, man findet einen besseren Weg, den Testcontainer zu konstruieren)

## Allgemeiner Aufbau von Skripten-unter-Tests

Es ist eher unüblich, ein _Scripts-under-test_ wie `startup.sh` ganz alleine auszuführen. Effektive Unit-Tests werden höchstwahrscheinlich zu einem Albtraum, wenn keine angemessene Skriptstruktur vorhanden ist. Da diese Skripte sich gegenseitig quellen _und_ Code ausführen, muss **alles** vorher eingerichtet werden: globale Variablen, Mocks von jedem einzelnen aufgerufenen Binary... und so weiter. Letztendlich würden die Tests eher auf einer End-to-End-Testebene als auf der Ebene der Einheitstests stattfinden.

Die gute Nachricht ist, dass das Testen einzelner Funktionen mit diesen kleinen Teilen möglich ist:

1. Sourcing-Ausführungsgarantien verwenden
2. Führen Sie Binärdateien und logischen Code nur innerhalb von Funktionen aus
3. Sourcen mit (dynamischen, aber fixierten) Umgebungsvariablen

### Execution guards work verwenden

Ermöglichen Sie das Sourcen mit _sourcing execution guards_ wie hier:

```bash
# yourscript.sh
function runTheThing() {
    echo "hello world"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runTheThing
fi
```

Die folgende `if`-Bedingung wird ausgeführt, wenn das Skript durch einen Aufruf über die Shell ausgeführt wird, aber nicht, wenn es von einer Quelle kommt:

```bash
$ ./yourscript.sh
hallo Welt
$ source yourscript.sh
$ runTheThing
Hallo Welt
$
```

Execution guards work funktionieren auch mit Parametern:

```bash
# yourscript.sh
Funktion runTheThing() {
    echo "${1} ${2}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runTheThingWithParameters "$@"
fi
```

Man beachte die korrekte Argumentübergabe mit `"$@"`, die auch Argumente mit Leerzeichen und dergleichen zulässt.

```bash
$ ./yourscript.sh hello world
hello world
$ source yourscript.sh
$ runTheThing hallo bash
hallo bash
$
```

### Binärdateien und Logikcode nur innerhalb von Funktionen ausführen

Umgebungsvariablen und Konstanten sind in Ordnung, aber sobald Logik außerhalb einer Funktion läuft, wird sie während des Script-Sourcings ausgeführt.

### Source mit (dynamischen, aber festgelegten) Umgebungsvariablen

Shellcheck sagt im Grunde, dass dies ein Tabu ist. Wie auch immer, solange der Testcontainer keine entsprechenden Skriptpfade zulässt, gibt es kaum eine Möglichkeit, dies zu umgehen:

```bash
sourcingExitCode=0
# shellcheck disable=SC1090
Quelle "${STARTUP_DIR}"/util.sh || sourcingExitCode=$?
if [[ ${sourcingExitCode} -ne 0 ]]; then
  echo "ERROR: An error occurred while sourcing /util.sh."
fi
```

Stellen Sie zumindest sicher, dass die Variablen in der Produktions- (z. B. `Dockerfile`) und Testumgebung richtig gesetzt sind (richten Sie eine env var in Ihrem Test ein).
