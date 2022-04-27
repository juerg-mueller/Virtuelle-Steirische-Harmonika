# Virtuelle-Steirische-Harmonika
Virtual Steirische Harmonica and Virtual Schwyzerörgeli

![Steirische](https://user-images.githubusercontent.com/14039478/165329913-ff17eb57-ce12-472d-b0f7-e0f2132c363e.png)
![Bedienung](https://user-images.githubusercontent.com/14039478/165444685-2193ac3e-08a5-4d41-a290-62c757684f32.png)

Tastatureingabe
===============

Mit der Tastatur (Buchstaben, Zahlen und Sonderzeichen) wird die Diskantseite
der Steirischen Harmonika abgebildet. Der Gleichton (mit Kreuz markiert) ist die H-Taste.

F5 bis F12 wird für die Bässe verwendet.
Mit Ctrl schaltet man von der äusseren Bassreihe auf die innere.

Mit der Shift-Taste ändert man die Balgbewegung.

Zusatzinformationen, welche im Synthesizer-Midi-Kanal mitgeliefert werden.
==========================================================================

Midi-Balg-Information, wird bei jedem Wechsel ausgegeben:

  B7 1f 00/01   ; 01 für Push; 00 für Pull
  
Die Tastatur-Spalten werden je einem eigenen Midi-Kanal zugewiesen.

  91 nn xx  für die äusserste Diskant-Spalte

  ..
  
  96 nn xx  für die äusserste Bass-Spalte

Diese Midi-Sequenzen lassen sich eindeutig in Griffschrift umwandeln. Für das Notenblatt-Korsett braucht es aber noch eine Quantisierung. 
