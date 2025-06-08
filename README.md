# Virtuelle-Steirische-Harmonika
Virtual Steirische Harmonica and Virtual Schwyzerörgeli

![VirtBoard](https://github.com/user-attachments/assets/cab16937-63af-49fc-8f90-448b7906913e)
![VirtuelleHarmonika](https://github.com/juerg-mueller/Virtuelle-Steirische-Harmonika/assets/14039478/aa3e9ba2-b486-46ad-b86f-bc66eddecee0)

Tastatureingabe
===============

Mit der Tastatur (Buchstaben, Zahlen und Sonderzeichen) wird die Diskantseite
der Steirischen Harmonika abgebildet. Der Gleichton (mit Kreuz markiert) ist die H-Taste.

F5 bis F12 wird für die Bässe verwendet.
Mit Ctrl schaltet man von der äusseren Bassreihe auf die innere.

Mit der Shift-Taste ändert man die Balgbewegung.

Zusatzinformationen, welche im Synthesizer-MIDI-Kanal mitgeliefert werden.
==========================================================================

MIDI-Balg-Information, wird bei jedem Wechsel ausgegeben (alle Angaben sind hexadezimal):

  B0 1f 00/01   ;01 für Push; 00 für Pull
  
Die Tastatur-Spalten werden je einem eigenen MIDI-Kanal zugewiesen.

  91 nn xx  für die äusserste Diskant-Spalte

  ..
  
  96 nn xx  für die äusserste Bass-Spalte

Diese MIDI-Sequenzen lassen sich eindeutig in Griffschrift umwandeln. Für das Notenblatt-Korsett braucht es aber noch eine Quantisierung. 

Das V3 Sound-Modul Accordion Master XXL lässt sich konfigurieren
----------------------------------------------------------------

MIDI-Bank und -Programm können für Diskant- und Bassseite getrennt konfiguriert werden und ganz speziell für den Accordion Master XXL.

https://www.youtube.com/watch?v=_RV61uIS8g4



Erweiterung vom 8. 5. 2025:
---------------------------

Das Projekt kann mit Delphi oder mit Lazarus compiliert werden.

Bei der Knopf-Abbildung gibt es neu: "Note anzeigen". 


Stand 1. Juni 2025
------------------

Branch 2.0 gesetzt.

Leider funktioniert Delphi in einer virtuellen Maschine von VMWare nicht mehr zufriedenstellend: Es blockiert die VM durch zu hohe Aktivitäten.
Deshalb habe ich mich entschlossen, meine Projekte mit Lazarus weiter zu entwickeln.

Nachteile:

- Die Belegung der PC-Tastatur kann ich nicht mehr beinflussen. "y" und "z" sind für US-Tastaturen vertaucht.

- Auch andere Funktionen sind noch eingeschränkt.


Vorteile

- Mit Lazarus ist ein Cross-Compiling möglich, d.h. ich kann Window '.exe'-Files auf meinem Linux System generieren.

- Ebenso kann die virtuelle Steirische Harmonika oder das Örgeli auch für Linux und für den MAC generiert werden. Dazu ist für die MIDI-Schnittstelle jeweils
eine Dynamische Library notwendig (https://github.com/thestk/rtmidi).

Hinweis zur Istallation von Lazarus: https://wiki.freepascal.org/fpcupdeluxe/de

Installation von rtmidi unter Linux: sudo apt install librtmidi-dev

Installation von rtmidi unter MAC: brew install rtmidi

