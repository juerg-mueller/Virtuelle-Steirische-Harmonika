﻿unit UBanks;

interface

type
  TStringArray = array[0..127] of string;
  PStringArray = ^TStringArray;

procedure GetBank(var Bank: TStringArray; BankNr: integer);

implementation

uses
  SysUtils;

type
  TBanks = array [0..42] of PStringArray;

const
  s0: TStringArray =
    ( '0 Acoustic Grand Piano (Flügel)',
      '1 Bright Acoustic Piano (Klavier)',
      '2 Electric Grand Piano',
      '3 Honky-tonk',
      '4 Electric Piano 1 (Rhodes)',
      '5 Electric Piano 2 (Chorus)',
      '6 Harpsichord (Cembalo)',
      '7 Clavi (Clavinet)',
      '8 Celesta',
      '9 Glockenspiel',
      '10 Music Box (Spieluhr)',
      '11 Vibraphone',
      '12 Marimba',
      '13 Xylophone',
      '14 Tubular Bells (Röhrenglocken)',
      '15 Dulcimer (Hackbrett)',
      '16 Drawbar Organ (Hammond)',
      '17 Percussive Organ',
      '18 Rock Organ',
      '19 Church Organ (Kirchenorgel)',
      '20 Reed Organ (Drehorgel)',
      '21 Accordion',
      '22 Harmonica',
      '23 Tango Accordion (Bandeon)',
      '24 Acoustic Guitar (Nylon)',
      '25 Acoustic Guitar (Steel - Stahl)',
      '26 Electric Guitar (Jazz)',
      '27 Electric Guitar (clean - sauber)',
      '28 Electric Guitar (muted - gedämpft)',
      '29 Overdriven Guitar (übersteuert)',
      '30 Distortion Guitar (verzerrt)',
      '31 Guitar harmonics (Harmonien)',
      '32 Acoustic Bass',
      '33 Electric Bass (finger)',
      '34 Electric Bass (pick - gezupft)',
      '35 Fretless Bass (bundloser Bass)',
      '36 Slap Bass 1',
      '37 Slap Bass 2',
      '38 Synth Bass 1',
      '39 Synth Bass 2',
      '40 Violin (Violine - Geige)',
      '41 Viola (Viola - Bratsche)',
      '42 Cello (Violoncello - Cello)',
      '43 Contrabass (Violone - Kontrabass)',
      '44 Tremolo Strings',
      '45 Pizzicato Strings',
      '46 Orchestral Harp (Harfe)',
      '47 Timpani (Pauke)',
      '48 String Ensemble 1',
      '49 String Ensemble 2',
      '50 SynthString 1',
      '51 SynthString 2',
      '52 Choir Aahs',
      '53 Voice Oohs',
      '54 Synth Voice',
      '55 Orchestra Hit',
      '56 Trumpet (Trompete)',
      '57 Trombone (Posaune)',
      '58 Tuba',
      '59 Muted Trumpet (gedämpfe Trompete)',
      '60 French Horn (französisches Horn)',
      '61 Brass Section (Bläsersatz)',
      '62 SynthBrass 1',
      '63 SynthBrass 2',
      '64 Soprano Sax',
      '65 Alto Sax',
      '66 Tenor Sax',
      '67 Baritone Sax',
      '68 Oboe',
      '69 English Horn',
      '70 Bassoon (Fagott)',
      '71 Clarinet',
      '72 Piccolo',
      '73 Flute (Flöte)',
      '74 Recorder (Blockflöte)',
      '75 Pan Flute',
      '76 Blown Bottle',
      '77 Shakuhachi',
      '78 Whistle (Pfeifen)',
      '79 Ocarina',
      '80 Square (Rechteck)',
      '81 Sawtooth (Sägezahn)',
      '82 Calliop',
      '83 Chiff',
      '84 Charang',
      '85 Voice',
      '86 Fifths',
      '87 Bass + Lead',
      '88 New Age',
      '89 Warm',
      '90 Polysynth',
      '91 Choir',
      '92 Bowed (Streicher)',
      '93 Metallic',
      '94 Halo',
      '95 Sweep',
      '96 Rain (Regen)',
      '97 Soundtrack',
      '98 Crystal',
      '99 Atmosphere',
      '100 Brightness',
      '101 Goblins',
      '102 Echoes',
      '103 Sci-Fi (Science Fiction)',
      '104 Sitar Ethnik',
      '105 Banjo',
      '106 Shamisen',
      '107 Koto',
      '108 Kalimba',
      '109 Bag Pipe (Dudelsack)',
      '110 Fiddle',
      '111 Shanai',
      '112 Tinkle Bell (Glocke)',
      '113 Agogo',
      '114 Steel Drums',
      '115 Woodblock',
      '116 Taiko Drum',
      '117 Melodic Tom',
      '118 Synth Drum',
      '119 Reverse Cymbal (Becken rückwärts)',
      '120 Guitar Fret. Noise (Gitarrensaitenquitschen)',
      '121 Breath Noise (Atem)',
      '122 Seashore (Meeresbrandung)',
      '123 Bird Tweet (Vogelgezwitscher)',
      '124 Telephone Ring',
      '125 Helicopter',
      '126 Applause',
      '127 Gun Shot (Gewehrschuss)'
      );

  s40: TStringArray =
      (
      '0 MAU 88',
      '1 MAU 88',
      '2 MAU 88+16',
      '3 MAU 4+88',
      '4 MAU 4+88+16',
      '5 MAU 888',
      '6 MAU 888',
      '7 MAU 888+16',
      '8 MAU 4+888',
      '9 MAU 4+888+16',
      '10 HO 88 Celeste',
      '11 HO 88 Celeste',
      '12 HO 88+16',
      '13 HO 4+88+16',
      '14 HO 816 Tango Repetition',
      '15 HO 816 Tango Repetition',
      '16 HO 816 Tango',
      '17 HO 4+816 Tango',
      '18 CAV VE10 Celeste 88',
      '19 CAV VE10 Celeste 88',
      '20 CAV VE10 Celeste 88+16',
      '21 CAV VE10 Celeste 88+1616',
      '22 CAV Double Bassoon',
      '23 CAV Double Bassoon',
      '24 V3 888 Repetition',
      '25 V3 888 Repetition',
      '26 V3 888 Repetition Off & 1 Oct',
      '27 MEN Retro 88',
      '28 MEN Retro 88',
      '29 MEN Retro 8888',
      '30 MEN Retro 8888',
      '31 MEN Retro 8888+8 Mega Musette',
      '32 MEN Retro Read 8',
      '33 MEN Retro Read 8',
      '34 MEN Retro Read 8 - cc1',
      '35 MEN Retro Read 8 - cc1',
      '36 SCA Super VI Reed 8',
      '37 SCA Super VI Reed 8',
      '38 SCA Super VI Reed 8 - cc11',
      '39 SCA Super VI 88',
      '40 SCA Super VI 8+16 Repetition',
      '41 SCA Super VI 4+8',
      '42 SCA Super VI 4+16 Repetition',
      '43 SCA Super VI 4+88',
      '44 SCA Super VI 4+8+16 Repetition',
      '45 SCA Super VI 4+88+ 16 Repetition',
      '46 SCA Super VI 488+16 Repetition',
      '47 BAL 888',
      '48 BAL 888',
      '49 GAL Vintage',
      '50 GAL Vintage',
      '51 BUG Reed 16 Jazz',
      '52 BUG Reed 16 Jazz',
      '53 BUG 4+16',
      '54 BUG 8+16',
      '55 BUG 4+8+16',
      '56 MEN 4+8 Tango',
      '57 BGA Reed 8 Cassotto',
      '58 BGA Reed 8 Cassotto',
      '59 BGA Reed 8 Cassotto - cc11',
      '60 BGA Reed 8 Cassotto - cc11',
      '61 V3 SVI & BUG 8+8 cassotto',
      '62 V3 SVI & BUG 8+8 - cc11',
      '63 V3 SVI & BUG 8+8 - tune+6',
      '64 V3 SVI & PM 8+8',
      '65 V3 SVI & PM 8+8',
      '66 V3 SVI & PM 8+8 B',
      '67 V3 SVI & PM 8+8 B',
      '68 V3 SVI & PM 8+8 tune 3',
      '69 V3 SVI & PM 8+8 tune 6',
      '70 V3 SVI & PM 8+8 tune 9',
      '71 HO Morino VM 888',
      '72 HO Morino VM 888',
      '73 HO 888+16',
      '74 HO 4+888',
      '75 HO 4+888+16',
      '76 Alpengold 888',
      '77 Alpengold 888',
      '78 HO Alpina 888',
      '79 HO Alpina 888',
      '80 ZU 88',
      '81 ZU 88',
      '82 ZU Reed 8',
      '83 ZU Reed 8',
      '84 ZU Reed 8 - cc11',
      '85 ZU Reed 8 - cc11',
      '86 V3 888 Swinging Musette',
      '87 V3 888 Swinging Musette',
      '88 V3 888',
      '89 V3 8+16',
      '90 Alpengold Reed 4',
      '91 HO Scot Gola 888',
      '92 HO Scot Gola 888',
      '93 HO Scot 888+16',
      '94 HO Scot 4+888',
      '95 HO Scot 4+888+16',
      '96 HO Scot Domino VM 888',
      '97 HO Domino 4816',
      '98 HO Scot J-Shand 888',
      '99 BOR Irish 888',
      '100 PM 88',
      '101 PM 88',
      '102 PM 88+16',
      '103 PM 4+88',
      '104 PM 4+88+16',
      '105 PM Reed 8',
      '106 PM Reed 8',
      '107 PM 8+16',
      '108 PM 8+16',
      '109 PM 4+8',
      '110 PM 4+8',
      '111 V3 8+8+8 A',
      '112 V3 8+8+8 B',
      '113 V3 8+8+8 C',
      '114 V3 8+8+8 D',
      '115 ACO Accordiola Benelux 888',
      '116 ACO Accordiola Benelux 888',
      '117 ACO Accordiola 888+8 Mega',
      '118 V3 8+8+8 tune 11',
      '119 V3 8+8+8 tune 17',
      '120 V3 8+8+8 tune 23',
      '121 V3 8+8+8 tune 29',
      '122 V3 8+8+8 tune 38',
      '123',
      '124',
      '125',
      '126',
      '127'
      );

  s41: TStringArray =
      (
      '0 WM Reed 8',
      '1 WM Reed 8',
      '2 V3 8+8+8 tune 0',
      '3 V3 8+8+8 tune 10',
      '4 V3 8+8+8 tune 20',
      '5 V3 88+8 tune 0',
      '6 V3 88+8 tune 20',
      '7 WM 888',
      '8 WM 888+8 Mega Tune',
      '9 STR Steirisch II',
      '10 Alpengold Steirische',
      '11 KAE Steirische',
      '12 KAE Steirische Posch I',
      '13 MUE Steirische',
      '14 HO Corona Vintage 888',
      '15 BR Irish Melodeon',
      '16 SER Netherland Melodeon',
      '17 VIC Bandeon - Repetition',
      '18 VIC Bandeon - Repetition',
      '19 Concertina',
      '20 NUS Schwyzerörgeli III',
      '21 NUS Schwyzerörgeli II',
      '50 SCA VI Bass',
      '51 SCA VI Bass',
      '52 VIC Bass',
      '53 BUG Bass 16',
      '54 BUG Bass 16',
      '55 BUG Bass 8',
      '56 BUG Bass 8',
      '57 BUG Bass 4',
      '58 BUG Bass 4',
      '59 BUG Bass 2',
      '60 BUG Bass 2',
      '61 BUG Bass 8+16',
      '62 BUG Bass 8+16',
      '63 BUG Bass 4+8+16',
      '64 BUG Bass 4+8+16',
      '65 SCA Bass VI + 32',
      '66 SCA Bass VI + 32',
      '67 SCA Chord',
      '68 SCA Chord',
      '69 BUG Chord 4',
      '70 BUG Chord 4',
      '71 BUG Chord 8',
      '72 BUG Chord 8',
      '73 BUG Chord 4+8',
      '74 BUG Chord 4+8',
      '75 BUG Chord 2+4',
      '76 BUG Chord 2+4',
      '90 WM Bass',
      '91 WM Bass',
      '92 WM Chord',
      '93 WM Chord',
      '94 AG Steirische Helikon',
      '95 AG Steirische Helikon soft off',
      '96 MUE Steirische Bass',
      '97 MUE Steirische Bass',
      '98 NUS Schwyzerörgeli Bass',
      '100 Attack Noise',
      '101 Finger Attak Noise - curve',
      '102 Attrack Bass',
      '103 Attack Chord Repetition',
      '104 Key off noise',
      '105 Reed off Musette',
      '106 Reed of Accordion',
      '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32', '33', '34', '35', '36', '37', '38', '39',
      '40', '41', '42', '43', '44', '45', '46', '47', '48', '49',
      '77', '78', '79',
      '80', '81', '82', '83', '84', '85', '86', '87', '88', '89',
      '99',
      '107', '108', '109',
      '110', '111', '112', '113', '114', '115', '116', '117', '118', '119',
      '120', '121', '122', '123', '124', '125', '126', '127'
      );

  s42: TStringArray =
      (
      '0 Cardovox Clar+Vib long',
      '1 Cardovox Clar+Vib medium',
      '2 Cardovox Clar+Vib short',
      '3 Cardovox 8+4+Vib flute long',
      '4 Cardovox 8+4+Vib flute medium',
      '5 Cardovox 8+4+Vib flute short',
      '6 Cardovox 8+Vib flute long',
      '7 Cardovox 8+Vib flute medium',
      '8 Cardovox 8+Vib flute short',
      '9 Cardovox 8-4+Vib flute long',
      '10 Cardovox 8-4+Vib flute medium',
      '11 Cardovox 8-4+Vib flute short',
      '12 Cardovox 8+Vib flute long',
      '13 Cardovox 8+Vib flute medium',
      '14 Cardovox 8+Vib flute short',
      '15 Cardovox 84 long',
      '16 Cardovox 84 medium',
      '17 Cardovox 84 short',
      '60 Vox IV Hawaii',
      '61 Vox IV Hawaii long',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', ''
      );

  Banks : TBanks =
      (
        @s0, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        @s40, @s41, @s42
      );


procedure GetBank(var Bank: TStringArray; BankNr: integer);
var
  i: integer;
begin
  if (BankNr >= 0) and (BankNr <= High(Bank)) and (Banks[BankNr] <> nil) then
    Bank := Banks[BankNr]^
  else begin
    for i := 0 to 127 do
      Bank[i] := IntToStr(i);
  end;
end;


end.