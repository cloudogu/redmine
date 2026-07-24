# Test, ob das Dogu in einer Air-Gapped-Umgebung funktionieren würde

Bei Redmine tritt immer wieder das Problem auf, dass Ruby-Gems während eines Upgrades installiert werden.
Das stellt in Air-Gapped-Umgebungen ein Problem dar.

Daher müssen wir mindestens testen, dass während eines Upgrades nicht auf rubygems.org zugegriffen wird.
Der folgende tcpdump-Befehl kann dabei hilfreich sein:
```bash
sudo tcpdump -i <your-interface> 'tcp dst port 80 or tcp dst port 443' and host rubygems.org
```
Wenn dabei während eines Upgrades etwas protokolliert wird, fehlen Gems, die dem Container hinzugefügt werden müssen.

Ein noch gründlicherer Test wäre, das Upgrade ohne Internetzugang auszuführen.
Wenn Sie den Container und die Dogu-Registry nicht spiegeln möchten, müssen Sie die Images vorher pullen und die dogu.json zuvor in
der lokalen Registry registrieren.
