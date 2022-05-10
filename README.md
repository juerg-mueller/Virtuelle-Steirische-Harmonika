# Virtuelle-Steirische-Harmonika
Virtual Steirische Harmonica and Virtual Schwyzerörgeli

![Steirische](https://user-images.githubusercontent.com/14039478/165329913-ff17eb57-ce12-472d-b0f7-e0f2132c363e.png)
![Bedienung](https://user-images.githubusercontent.com/14039478/166447306-0a542911-c92a-44f3-b401-521da8d361c6.png)

Tastatureingabe
===============

Mit der Tastatur (Buchstaben, Zahlen und Sonderzeichen) wird die Diskantseite
der Steirischen Harmonika abgebildet. Der Gleichton (mit Kreuz markiert) ist die H-Taste.

F5 bis F12 wird für die Bässe verwendet.
Mit Ctrl schaltet man von der äusseren Bassreihe auf die innere.

Mit der Shift-Taste ändert man die Balgbewegung.

Zusatzinformationen, welche im Synthesizer-MIDI-Kanal mitgeliefert werden.
==========================================================================

MIDI-Balg-Information, wird bei jedem Wechsel ausgegeben:

  B0 1f 00/01   ;01 für Push; 00 für Pull
  
Die Tastatur-Spalten werden je einem eigenen MIDI-Kanal zugewiesen.

  91 nn xx  für die äusserste Diskant-Spalte

  ..
  
  96 nn xx  für die äusserste Bass-Spalte

Diese MIDI-Sequenzen lassen sich eindeutig in Griffschrift umwandeln. Für das Notenblatt-Korsett braucht es aber noch eine Quantisierung. 

Das V3 Sound-Modul Accordion Master XXL lässt sich konfigurieren
----------------------------------------------------------------

MIDI-Bank und -Programm können für Diskant- und Bassseite getrennt konfiguriert werden und ganz speziell für den Accordion Master XXL.
