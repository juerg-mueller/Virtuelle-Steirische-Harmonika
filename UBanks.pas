﻿unit UBanks;

interface

type
{$ifdef FPC}
  TArrayOfString = array of string;
{$else}
  TArrayOfString = TArray<string>;
{$endif}
  PArrayOfString = ^TArrayOfString;


const
  bank_list: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 - General Midi',
      '1 - Piano',
      '2 - E-Piano',
      '3 - Organ',
      '4 - Organ - Drawbar Registrations',
      '5 - Perc. Tuned Instr.',
      '6 - String Instr.',
      '7 - Guitar',
      '8 - Harmonica and more',
      '9 - Full Strings & Disco Strings',
      '10 - Solo Strings',
      '11 - Synth Strings',
      '12 - Brass Solo',
      '13 - Brass Section',
      '14 - Classic Brass',
      '15 - Saxophon',
      '16 - Winds',
      '17 - Classic Winds',
      '18 - Choir',
      '19 - Bass',
      '20 - Synthesizer and Bass',
      '21 - FX and Percussion',
      '23 - Herzing Universal',
      '24 - Herzing Universal',
      '40 - Accordion French, German, Slovenija and others',
      '41 - Melodeon, Bass, Chord Acc. and Chord Melo.',
      '42 - Cordovox, Hawaii',
      '71 - Herzing Celtic Sound',
      '72 - Herzing Int. Accordion',
      '74 - Herzing Orgel',
      '75 - Herzing Folklore',
      '80 - Herzing Alpin Accordion',
      '81 - Herzing Solo',
      '82 - Herzing Strings & Synth. Bass',
      '83 - Herzing Brass Bass',
      '84 - Herzing Guitarr',
      '98 - Model Herzing',
      '99 - Herzing Organ'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

procedure GetBank(var Bank: TArrayOfString; BankNr: integer);
procedure CopyBank(var Bank: TArrayOfString; Bank_: PArrayOfString);

implementation

uses
  SysUtils;

type
  TBanks = array [0..99] of PArrayOfString;

const
  {$ifdef FPC}
  s0: TArrayOfString = (
  {$else}
   s0: TArray<string> = [
  {$endif}
      '0 Acoustic Grand Piano (Fluegel)',
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
      '14 Tubular Bells (Roehrenglocken)',
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
      '28 Electric Guitar (muted - gedaempft)',
      '29 Overdriven Guitar (uebersteuert)',
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
      '59 Muted Trumpet (gedaempfe Trompete)',
      '60 French Horn (franzoesisches Horn)',
      '61 Brass Section (Blaesersatz)',
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
      '73 Flute (Floete)',
      '74 Recorder (Blockfloete)',
      '75 Pan Flute',
      '76 Blown Bottle',
      '77 Shakuhachi',
      '78 Whistle (Pfeifen)',
      '79 Ocarina',
      '80 Square (Rechteck)',
      '81 Sawtooth (Saegezahn)',
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
      '119 Reverse Cymbal (Becken rueckwaerts)',
      '120 Guitar Fret. Noise (Gitarrensaitenquitschen)',
      '121 Breath Noise (Atem)',
      '122 Seashore (Meeresbrandung)',
      '123 Bird Tweet (Vogelgezwitscher)',
      '124 Telephone Ring',
      '125 Helicopter',
      '126 Applause',
      '127 Gun Shot (Gewehrschuss)'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s1: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Grand Piano',
      '2 Rock Piano',
      '4 Classic Grand Piano',
      '6 Honky Tonk',
      '7 Grand Latin Octave',
      '8 Upright Piano',
      '9 Grand Piano - Layered EP-FM',
      '10 Grand Piano & E-Grand Rock - Layered MKS & CP Attack',
      '11 Grand Piano - Layered Pad',
      '12 Grand Piano - Layered Strings',
      '100 Grand Piano - pp samples only',
      '101 Grand Piano - p samples only',
      '102 Grand Piano - mp samples only'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s2: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '0 Electric Grand',
      '1 Electric Grand & Mic. Attack',
      '2 Electric Grand MKS',
      '3 Electric Grand Mic. Attack - curved velocity - layer this sound',
      '4 E-Piano MK1 Classic',
      '5 E-Piano MK1 Classic',
      '6 E-Piano MK1 Classic',
      '7 E-Piano MK1 Classic',
      '8 E-Piano MK1 Classic',
      '9 E-Piano MK1 Classic',
      '10 E-Piano MK1 Classic',
      '11 E-Piano V3 Bella',
      '12 E-Piano V3 Bella - Note Off 1 Octave up',
      '13 E-Piano V3 Bella - Layered Cortales',
      '14 E-Piano V3 Bella - Layered Pad',
      '15 E-Piano Wurlitzer A200',
      '16 E-Piano Wurlitzer A200 - Vibrato 1',
      '17 E-Piano Wurlitzer A200 - Vibrato 2',
      '18 E-Piano DX Classic',
      '19 E-Piano FM',
      '20 E-Piano FM - Layered Bell',
      '21 E-Piano FM - Filter',
      '22 E-Piano FM - Note-off',
      '23 E-Piano FM - Layered MKS',
      '24 E-Piano FM - Vibrato 1',
      '25 E-Piano FM - Vibrato 2',
      '26 E-Piano FM - Layered Pad',
      '27 E-Piano FM - Layered Bell & Pad'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s3: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '0 Organ 776555678 - slow Rotary',
      '1 Organ 776555678 - fast Rotary',
      '2 Organ 800000568 - slow Rotary',
      '3 Organ 800000568 - fast Rotary',
      '4 Organ 008530000 - slow Rotary',
      '5 Organ 008530000 - fast Rotary',
      '6 Organ 800000000 - slow Rotary',
      '7 Organ 800000000 - fast Rotary',
      '8 Organ 807800000 - slow Rotary',
      '9 Organ 807800000 - fast Rotary',
      '10 Organ 804708000 - slow Rotary',
      '11 Organ 804708000 - fast Rotary',
      '12 Organ 800008000 - slow Rotary',
      '13 Organ 800008000 - fast Rotary',
      '14 Organ 800000008 - slow Rotary',
      '15 Organ 800000008 - fast Rotary',
      '16 Organ 687600000 - slow Rotary',
      '17 Organ 687600000 - fast Rotary',
      '18 Organ 888 perc. slow',
      '19 Rorck Organ',
      '20 Hammond Full',
      '21 Hammond L100 Retro KW1',
      '22 Hammond L100 Retro KW2',
      '23 German Organ DB slow',
      '24 German Organ DB fast',
      '25 German Organ FL slow',
      '26 German Organ FL fast',
      '27 Version UK',
      '28 Theatre Organ Mighty Tower',
      '29 Theatre Organ + Xylophone Reiteration',
      '30 Theatre Organ + Glocken Reinteration',
      '31 Theatre Organ Piston 2',
      '32 Theatre Organ Piston 2 + Xylo. Reiteration',
      '33 Theatre Organ Piston 2 + Glocken Reiteration',
      '34 Theatre Organ Royal',
      '35 Theatre Organ Royal + Xylo. Reiteration',
      '36 Theatre Organ Royal + Glocken Reiteration',
      '37 Theatre Organ Pedal Bass',
      '38 Organ Hause',
      '39 Combo Retro Vibratio 1',
      '40 Combo Retro Vibratio 2',
      '41 Classic Organ Tutti 1',
      '42 Classic Organ Tutti 2',
      '43 Classic Organ Pipe Flute',
      '44 Classic Organ Pipe Combi',
      '45 Classic Organ Pedal Flute 16',

      '118 Theatre Organ Glocken Hit',
      '119 Theatre Organ Glocken short',
      '120 Theatre Organ Glocken Reiteration',
      '121 Theatre Organ Xylophone Hit',
      '122 Theatre Organ Xylophone Reiteration',
      '123 Theatre Organ Xylophone Hit + Reiteration',
      '124 Theatre Organ Glocken Reiteration',
      '125 Theatre Organ Xylophone Reiteration',
      '126 Organ Click'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}


  s4: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Jimmy Smith',
      '1 Joey De Francesco',
      '2 Charles Earland',
      '3 Brian Auger',
      '4 Garner Set',
      '5 Piano Set',
      '6 Walter Wanderley',
      '7 Whistle',
      '8 Gospel Set',
      '9 Blues Set',
      '10 Easy Listening',
      '11 Jimmy Smith',
      '12 Jimmy Smith',
      '13 Joey De Francesco',
      '14 Ballad 2',
      '15 Jesse Crawford',
      '16 Joey De Francesco',
      '17 Brooker T. Jones',
      '18 Green Onions',
      '19 Matthew Fisher',
      '20 Jimmy Mc Griff Gospel',
      '21 Chords',
      '22 Chords',
      '23 Walter Wanderley',
      '24 Walter Wanderley',
      '25 Lenny Dee',
      '26 Lenny Dee',
      '27 Lenny Dee',
      '28 Ethel Smith',
      '29 Ken Griffin',
      '30 Jon Lord',
      '31 Jimmy Smith',
      '32 Jimmy Smith',
      '33 Exclusive',
      '34 Exclusive',
      '35 Standard',
      '36 Standard',
      '37 Standard',
      '38 Standard',
      '39 Standard',
      '40 Experiment',
      '41 Experiment',
      '42 Experiment',
      '43 Experiment',
      '44 Experiment',
      '45 Bars 1st Three',
      '46 Bar 1st Four',
      '47 Bar 16',
      '48 Bar 16+8',
      '49 Bar 8',
      '50 Bar 5 1/3',
      '51 Vib A',
      '52 Vib B',
      '53 Full Organ',
      '54 Highest',
      '55 Middle Mix',
      '56 Bar 1st Three',
      '57 Bar 1st Four',
      '58 Bar 16',
      '59 Bar 16+8',
      '60 Bar 8',
      '61 Bar 5 1/3',
      '62 Bar 4',
      '63 Bar 2 2/3',
      '64 Bar 2',
      '65 Bar 1 3/5',
      '66 Bar 1 1/3',
      '67 Bar 1',
      '68 Percussion 2',
      '69 Percussion 2 long',
      '70 Percussion 3',
      '71 Percussion 3 long',
      '72 Organ Click'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s5: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Music Box',
      '1 Music Box octave delay',
      '2 Music Box octave delay - soft Attack',
      '3 Vibraphone',
      '4 Vibraphone short Release',
      '5 Vibraphone soft Attack',
      '6 Vibraphone no Vibrato',
      '7 Vibraphone no Vibrato shot Release',
      '8 Vibraphone fast Tremolo',
      '9 Celeste',
      '10 Tinkle',
      '11 Marimba',
      '12 Marimba octave Delay',
      '13 Marimba & Xylophone',
      '14 Xylophone',
      '15 Xylophone octave Delay',
      '16 Tabular Bell',
      '17 Tabular Bell 2',
      '18 Timpani',
      '19 Kalimba',
      '20 Cortales',
      '21 Steel Drum',
      '22 Alpin Bell Hit',
      '23 Alpin Bell Roll',
      '24 Alpin Bell Hit & Roll',
      '25 Bell'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s6: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Harpsichord',
      '1 Harpsichord & Octave',
      '2 Clavinet 1',
      '3 Clavinet 21',
      '4 Zither',
      '5 Dulcimer 3 strings',
      '6 Dulcimer 3 strings+',
      '7 Dulcimer 3 strings Tremolo',
      '8 Dulcimer 3 strings bowed',
      '9 Dulcimer 5 strings',
      '10 Dulcimer 5 strings+',
      '11 Dulcimer 5 strings Tremolo',
      '12 Dulcimer 5 strings bowed',
      '13 Harp',
      '14 Harp long'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s7: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Guitar Nylon',
      '1 Guitar Nylon soft',
      '2 Guitar Nylon Octave',
      '3 Guitar Nylon Slide Velocity',
      '4 Guitar Nylon Harmonics',
      '5 Guitar Steel 1',
      '6 Guitar Steel 1 soft',
      '7 Guitar Steel 1 hard',
      '8 Guitar Steel 1 double',
      '9 Guitar Steel 1 mute',
      '10 Guitar Steel 1 bowed',
      '11 Guitar Steel 2',
      '12 Guitar Steel 2 soft Attack',
      '13 Guitar Steel 3',
      '14 Guitar Steel 3 soft Attack',
      '15 Banjo',
      '16 Banjo Slide Velocity',
      '17 Mandoline Italian',
      '18 Mandoline Ensemble Tremolo',
      '19 Mandoline Ensemble',
      '20 Mandoline Ensemble Split Velocity',
      '21 Guitar Jazz 1',
      '22 Guitar Jazz 2',
      '23 Guitar Jazz & Octave',
      '24 Pedal Steel Vibrato',
      '25 Pedal Steel',
      '26 Pedal Steel bowed',
      '27 Pedal Steel Slide Velocity',
      '28 Guitar Jazz 3',
      '29 Guitar Jazz 3 Chicken Picking',
      '30 Guitar Jazz 4',
      '31 Guitar Jazz 4 Chicken Picking',
      '32 E-Guitar US clean',
      '33 E-Guitar US mute',
      '34 E-Guitar BR clean HPF',
      '35 E-Guitar BR mute HPF',
      '36 E-Guitar Overdrive',
      '37 E-Guitar US Distortion',
      '38 Rhythm Guitar',
      '39 Rhythm Guitar',
      '123 Nylon Guitar Percussion',
      '124 Guitar stroke',
      '125 Guitar noise',
      '126 Guitear Ghost Note'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s8: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Harmonica',
      '1 Harmonica Slide velo. 116-117',
      '2 Harmonica Vibrato',
      '3 Accordia',
      '4 Jew''s harp'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s9: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '0 Full Strings 1 Chamber - velocity to Attack',
      '1 Full Strings 1 Chamber - Release shot',
      '2 Full Strings 1 Chamber - Release medium',
      '3 Full Strings 1 Chamber - Release long',
      '4 Full Strings 1 Chamber - Slow Attack',
      '5 Full Strings 2 Chamber - Release shot',
      '6 Full Strings 2 Chamber - Release medium',
      '7 Full Strings 2 Chamber - Release long',
      '8 Full Strings 2 Chamber - forte only',
      '9 Full Strings 2 Chamber - piano only',
      '10 Full Strings 3 Chamber - velocity to Attack time',
      '11 Full Strings 3 Chamber - layerd 4',
      '12 Full Strings 3 Chamber - slow',
      '13 Full Strings 3 Chamber - standard',
      '14 Full Strings Tremolo',
      '15 Full Strings Pizzicato'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s10: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Geige',
      '1 Geige - soft Attack',
      '5 Geige - velocity slide',
      '6 Celtic Fiddle',
      '8 Celtic Fiddle Slide',
      '9 Classic Solo Violin - soft Attack',
      '10 Classic Solo Violin - marcato',
      '16 Classic Solo Viola',
      '17 Classic Solo Viola - marcato',
      '23 Classic Solo Cello',
      '24 Classic Sollo Cello - marcato',
      '30 Classic Solo Contra Bass',
      '31 Classic Solo Contra Bass - marcato'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s11: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Strings PWM',
      '1 Strings PWM',
      '2 Strings PWM',
      '3 Strings PWM',
      '4 Strings MKS',
      '5 Strings MKS',
      '6 Strings MKS',
      '7 Strings MKS',
      '8 Strings Retro Solino',
      '9 Stringmaster Retro',
      '10 Strings M12',
      '11 Strings M12',
      '12 Strings M12',
      '13 Strings M12 Notch',
      '14 Strings M12 Notch',
      '15 Strings M12 Notch',
      '33 OB Strings fast',
      '34 OB Strings slow',
      '35 OB Strings II mono LPF',
      '36 OB Strings II mono BPF',
      '37 OB Strings II mono HPF'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s12: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Trumpet 1',
      '1 Trumpet 1',
      '2 Trumpet 1',
      '3 Trumpet 1',
      '4 Trumpet 1',
      '5 Trumpet 1',
      '6 Trumpet 1',
      '7 Trumpet 1',
      '8 Trumpet 2 Ivan',
      '9 Trumpet 2 Ivan',
      '10 Trumpet 2 Ivan',
      '11 Trumpet 2 Ivan',
      '12 Trumpet 3 Vibrato',
      '13 Trumpet 3 Vibrato',
      '14 Trumpet 3 Vibrato',
      '15 Trumpet 3 Vibrato',
      '16 Trumpet 3 Vibrato',
      '17 Trumpet 3 Vibrato',
      '18 Trumpet 3 High Lead - no Vibrato',
      '19 Cornet',
      '20 Cornet',
      '21 Cornet',
      '22 Cornet',
      '23 Trumpet mute',
      '24 Trumpet mute - Repetition / Auto Variation',
      '25 Flugelhorn',
      '26 Trombone Vibrato',
      '27 Trombone',
      '28 Trombone damper',
      '29 F-Horn',
      '30 Tenorhorn',
      '31 Tenorhorn Vibrato',
      '32 Alphorn',
      '33 Baritone Horn Vibrato',
      '34 Baritone Horn Staccato',
      '35 Tuba',
      '36 Tuba soft'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s13: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 US Trumpet Section - dynamic split',
      '1 US Trumpet Section - forte',
      '2 US Trumpet Section - mezzo',
      '3 US Trumpet Section - fast fall',
      '4 US Trumpet Section - medium fall',
      '5 US Trumpet Section - split',
      '6 US Trombone Section - dynamic split',
      '7 US Trombone Section - forte',
      '8 US Trombone Section - mezzo',
      '9 US Trombone Section - fast fall',
      '10 US Trombone Section - medium fall',
      '11 US Trombone Section - split',
      '12 US Trumpet & Trombone Section - dynamic split',
      '13 US Trumpet & Trombone Section - forte',
      '14 US Trumpet & Trombone Section - mezzo',
      '15 Flugelhorn Duo',
      '16 Tenorhorn Ensemble Vibrato',
      '17 Alphorn Duett',
      '18 Alphorn Trio',
      '19 Alphorn Ensamble'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s14: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '6 Classic Horn Solo',
      '20 Horn Ensemble - velocity split',
      '21 Horn Ensemble - piano only',
      '22 Horn Ensemble - staccato',
      '23 Tuba Ensemble',
      '126 Horn Ensemble - Riff up'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s15: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Soprano Sax',
      '1 Soprano Sax softer',
      '2 Soprano Sax harder',
      '3 Soprano Sax and noise',
      '4 Soprano Sax Slide',
      '5 Soprano Sax II more Vibrato',
      '6 Alto Sax',
      '7 Alto Sax softer ',
      '8 Alto Sax harder',
      '9 Alto Sax breath',
      '10 Alto Sax Slide',
      '11 Tenor Sax',
      '12 Tenor Sax softer',
      '13 Tenor Sax harder',
      '14 Tenor Sax breath',
      '15 Tenor Sax Slide',
      '16 Max Jazz Tenor',
      '17 Max Jazz Tenor',
      '18 Max Jazz Tenor soft',
      '19 Max Jazz Tenor',
      '20 Max Jazz Tenor Vibrato less delay',
      '21 Max Jazz Tenor soft',
      '22 Max Jazz Tenor Slide',
      '23 Max Jazz Tenor Slide soft',
      '24 Tenor Sax Funky',
      '25 Tenor Sax Funky growl',
      '26 Tenor Sax Funky Spli',
      '27 Baritone Sax',
      '28 Sax Section 1',
      '29 Sax Section 2',
      '126 Sax Breath Noise only'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s16: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Clarinet',
      '1 Clarinet soft',
      '2 Clarinet Slide',
      '3 Hugo Clarinet - no loop',
      '4 Hugo Clarinet Slide',
      '5 Clarinet Vito Tradition',
      '6 Clarinet Vito Tradition',
      '7 Clarinet Vito Tradition soft',
      '8 Clarinet Vito Tradition',
      '9 Clarinet Vito Tradition',
      '10 Piccolo',
      '11 Flute',
      '12 Flute EQ',
      '13 Flute High Pass Filter',
      '14 Low Whistle',
      '15 Panflute',
      '16 Shakuhachi',
      '17 Celtic High Wistle',
      '18 Celtic High Wistle Grece Note AV',
      '19 Celtic High Wistle Slide',
      '20 Bottle',
      '21 Bottle Q',
      '22 Bottle LFO',
      '23 Whistle',
      '24 Okarina',
      '25 Highland Pipers & Drone Ensemble',
      '26 Ullian Piper & Drone',
      '27 Ullian Piper & Drone Grace Note AV',
      '28 Ullian Piper & Drone Slide',
      '29 Ullian Drone & Chords',
      '30 Border Pipe',
      '31 Border Pipe AV',
      '32 Border Pipe Slide ',
      '33 Border Pipe Drone'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s17: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Classic Flute',
      '1 Classic Flute - just piano',
      '2 Classic Flute - staccato',
      '3 Oboe',
      '4 Oboe - just piano',
      '5 Oboe - staccato',
      '6 English Horn',
      '7 English Horn - just piano',
      '8 English Horn - staccato',
      '9 Classic Clarinet',
      '10 Classic Clarinet - just piano',
      '11 Classic Clarinet - staccato',
      '12 Bassoon',
      '17 Flute Ensemble',
      '18 Clarinet Ensemble'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s18: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Classic Choir Aah',
      '1 Classic Choir Aah - Filter',
      '2 Classic Choir Ooh',
      '3 Classic Choir Ooh - Filter',
      '4 Choir Pop Ooh',
      '5 Choir Pop Ooh - Filter',
      '6 Synth Voice',
      '7 Classic Voice',
      '8 Boys Aah',
      '9 Boys Bap',
      '10 Boys Daa',
      '11 Boys Doo Bass',
      '12 Boys Doo',
      '13 Boys Falsetto Ooh',
      '14 Boys Hmm',
      '15 Boys Laa',
      '16 Boys Mix Ooh',
      '17 Boys Ooh',
      '18 Girls Aah',
      '19 Girls Doo',
      '20 Girls Ooh',
      '126 Vice Kit - mapping like Drum Kit 58'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s19: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 E-Bass 1',
      '1 E-Bass 1 & Note off',
      '2 E-Bass 1 Slide',
      '3 E-Bass 2',
      '4 E-Bass 2 & Note off',
      '5 E-Bass 3',
      '5 E-Bass 3 Slide',
      '7 E-Bass 4',
      '8 E-Bass 5 Picking 1',
      '9 E-Bass 5 Picking 1 & Note off',
      '10 E-Bass 6 Picking 2',
      '11 E-Bass 6 Picking 2 & Note off',
      '12 E-Bass 7',
      '13 E-Bass 7 - Repetition',
      '14 E-Bass 7 & Note off - Repetition',
      '15 E-Bass Fretless',
      '16 E-Bass Slap 1',
      '17 E-Bass Slap 1 & Note off',
      '18 E-Bass Slap 2',
      '19 E-Bass Slap 2 & Note off',
      '20 Upright Jazz Bass',
      '21 Upright Jazz Bass & Note off',
      '22 Upright Jazz Bass',
      '23 Upright Jazz Bass & Note off',
      '24 Upright Jazz Bass',
      '25 Upright Jazz Bass & Note off',
      '26 Upright Jazz Bass',
      '27 Upright Bass',
      '28 Upright Bass',
      '29 Upright Bass',
      '30 Upright Bass DI',
      '31 Upright Bass DI',
      '32 Upright Bass DI long Release',
      '33 Upright Bass DI long Release',
      '34 Bowed Upright Bass',
      '34 Bowed Upright Bass'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s20: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Bells & Pad',
      '1 Digital Pad',
      '2 OBX & Wavebell',
      '3 DX1 Toy',
      '4 Star Theme',
      '5 Brightness',
      '6 OB & Noise',
      '7 Atmos',
      '8 Brass Comp',
      '9 Brass Rex',
      '10 Polysynth Classic',
      '11 Halo Pad',
      '12 Caliope',
      '13 Charang',
      '14 Fairly Space',
      '15 Echo Drop',
      '16 VF Vox',
      '17 Bass & Lead',
      '18 Fantasia',
      '19 Bowed Glass',
      '20 Soft Pad',
      '21 Ice Rain',
      '22 Goblin',
      '23 Sound Track',
      '24 Atmosguitar',
      '25 Bottle Soft',
      '26 Polysynth Classic 5th',
      '27 Square Lead',
      '28 P5 Bass',
      '29 Saw',
      '30 Saw Env',
      '31 C-Lead',
      '32 Solo Fox',
      '33 Metal Pad',
      '34 Juno Sweep',
      '35 Vangbrass',
      '36 Crystal',
      '37 FM8',
      '38 Mo55',
      '39 DX Bell',
      '40 OBSoft 1',
      '41 OBSoft',
      '42 Hook',
      '43 FM Pluk',
      '44 FM Brazz',
      '45 Ice',
      '46 Bo Hook',
      '47 VPhrase',
      '48 VP 1',
      '49 Grace',
      '50 Noise',
      '51 Digirace',
      '52 Shinner',
      '53 Pad-A',
      '54 Vibro',
      '55 Digisi',
      '56 Alex',
      '57 VZ Bell',
      '58 VZ 1',
      '59 Mizoo',
      '60 Bellko',
      '61 Bellz',
      '62 Analog OB',
      '63 M3 Osc',
      '64 M12 Brass',
      '65 M12 Brass ENV',
      '66 OB Lead',
      '67 OB Arp',
      '68 OBell',
      '69 OBrass',
      '70 Mach 1',
      '71 Brazza',
      '72 Brasso',
      '73 T8 Super Bass',
      '74 T8 Super Bass ENV',
      '75 Dells',
      '76 Pulse',
      '77 Polso',
      '78 PWD 24',
      '79 Xylophone',
      '80 Champo',
      '81 Jippo',
      '82 JX Arp',
      '83 Bamarimba',
      '84 JCO 10',
      '85 JX Bell',
      '86 Stab Brass',
      '87 Clouds',
      '88 Bell Hit HP Filter',
      '89 OB Noise',
      '90 Noise Down',
      '91 Voxo - Notch Filter 12',
      '92 APad Notch - Filter 12',
      '116 Classic Synth Bass',
      '117 Classic Synth Bass Rezo',
      '118 JBass 1',
      '119 JBass 2',
      '120 JBass 3',
      '121 JBass soft',
      '122 CS Classic Bass',
      '123 MoBass',
      '124 MoBass ENV',
      '125 XBass 1',
      '126 XBass 2'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s21: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Orchestra Hit Major',
      '1 Orchestra Hit Minor',
      '62 Synth FX down',
      '63 Synth FX up',
      '64 Drum Kit 0',
      '64 Percussion Kit - 56',
      '66 Classic Perkussion - 48',
      '67 Drumkit Accordion - 67'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s23: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 SQ Lead 1',
      '2 Lead Analog 1',
      '3 TB303 Lead',
      '4 Saw JP8',
      '5 Mini Moo 1',
      '6 Hook Lead 1',
      '7 Hook Lead CS 8',
      '8 Hook Lead 2',
      '9 M-Synth Rezo',
      '10 M-Synthz',
      '11 Bass & Lead 2',
      '12 FM Plunk',
      '13 FM Brass',
      '14 La Boum+',
      '15 La Boum',
      '16 Pad 200',
      '17 Pad 300',
      '18 Pad 300 mono',
      '19 Pad 302 HPF',
      '20 Polysynth',
      '21 Pad Juno',
      '22 DX Brass',
      '23 DX Brass HPF',
      '25 FX Bello',
      '26 Atmo Bell',
      '27 Atmoness',
      '28 PWS stereo',
      '29 PWS mono',
      '30 SYX 1 Bell',
      '31 SYX 2 Bell',
      '35 Arpegy FM',
      '36 Arpegyko',
      '38 Arpeg SY',
      '39 Arpeg TEK',
      '40 Overhome',
      '41 Bellave stereo',
      '42 Bellave mono',
      '43 PX Bell',
      '44 FM Bell',
      '45 Analog Bell',
      '46 Modular 55',
      '47 Bright mono',
      '51 Lovesynth',
      '52 Bright 8',
      '53 Bright O',
      '54 Bright F',
      '55 Beauty 7',
      '56 Beauty F',
      '57 Bell Hit',
      '58 Bell Spectra',
      '60 Electronic Steel',
      '62 Strings High',
      '63 Strings ENV',
      '68 Cloudy',
      '69 Strings',
      '70 Fantasy mono',
      '71 Matrix 12 stereo',
      '72 Matrix 12 mono',
      '73 Full Strings 740',
      '74 Xylophon',
      '75 Xylophon + Oct.',
      '76 Choir Oooh',
      '77 Choir Ahh',
      '78 Cornet Vibrato',
      '79 Cornet soft',
      '80 Cornet hard',
      '81 Cornet porta up',
      '82 Tenorsax Ballroom',
      '83 Tenorsax Jazz',
      '84 Nylon Guitar Solo soft',
      '85 Jazz Vibraphon',
      '86 Steel Guitar',
      '87 Fiddle Celtic',
      '88 Woodblock',
      '89 Taiko',
      '90 Full Strings forte',
      '92 Full Strings piano',
      '93 Banjo Slide up 116',
      '98 Guita Spanish Slide up 116',
      '99 Accoustic Steel 2',
      '100 Accoustic Steel 2 soft',
      '101 Hackbrett Appenzeller',
      '102 Alpensellen Hit',
      '103 Alpensellen Roll',
      '104 Choir Ooo soft',
      '105 Synth Hook Line',
      '106 Synth Pad OBX',
      '107 Synth Pad OBX soft',
      '108 Synth Pad OBX warm ',
      '109 Synth Pad OBX ENV',
      '110 DX1 Bell Toy',
      '111 DX1 Bell Toy delay',
      '112 Trumpet AV mute',
      '113 E-Bass Slap 1',
      '114 E-Bass Slap 2',
      '115 Glockenspiel',
      '116 Harp',
      '117 Vibraphon Vibrato',
      '126 FX Plattler',
      '127 Fredy Pfister'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s24: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Full Strings 2',
      '2 Full Strings 1 log Release',
      '3 Full Strings 2 slow',
      '4 Full Strings Detached Curve',
      '5 Full Strings 2 fad',
      '6 Synth Strings Solina',
      '7 Full Strings 2 LFO',
      '8 Full Strings 2 Filter ENV',
      '9 Banjo',
      '10 Steel Drum',
      '11 Marimba',
      '13 Trumpet Section',
      '14 Tenor Sax Funky',
      '15 Tenor Sax Growl',
      '16 Tenor Sax SP 116',
      '17 Alto Sat',
      '18 Alto Sax soft',
      '19 Choir Ooh',
      '20 Choir Ohh',
      '21 Clarinet Swiss Carlo',
      '22 Clarinet Swiss Carlo EQ',
      '23Sopran Sax Swiss Carlo',
      '24 Flute',
      '25 Flute EQ',
      '26 Fantasia',
      '27 Brightness',
      '28 Synth Brass 3',
      '29 Star Them 2',
      '30 Saw Lead 1',
      '31 Saw Lead 2',
      '32 Synth Brass 4',
      '33 Rhythm Guitar Steel',
      '34 Rhythm Guitar Steel soft',
      '35 Rhythm Guitar fade less LE',
      '36 Rhythm Guitar fade',
      '37 Alto Sax',
      '38 Alto Sax soft',
      '39 Alto Sax hard',
      '40 Alto Sax soft noise',
      '41 Tenor Sax',
      '42 Tenor Sax soft',
      '43 Tenor Sax hard',
      '44 Tenor Sax soft noise',
      '45 Tenor Sax medium',
      '46 Tenor Sax Section',
      '47 Tenor Sax Section soft',
      '51 E-Piano FM',
      '52 E-Piano FM Dyno',
      '53 E-Piano FM & Bell',
      '54 Grand Piano - no velocity',
      '55 Grand Piano',
      '56 Grand Piano bright',
      '57 Honky Tonk',
      '58 E-Grand',
      '59 Guitar Accustic Steel soft',
      '60 Guitar Jazz',
      '61 Guitar Jazz clean',
      '62 Guitar Jazz mute',
      '63 Bass Fretless',
      '64 Brass Section YT 1',
      '65 Guitar Distortion',
      '66 Solo Violin Classic',
      '67 Solo Viola Classic',
      '68 Solo Cello Classic',
      '69 Solo Contrabass Classic',
      '70 Full Strings Tremolo',
      '71 Full Strings Pizzi',
      '72 Guitar Overdrive',
      '73 Sax Sopran',
      '74 Sax Bariton',
      '75 Sax Sopran soft',
      '76 Panflute',
      '77 Flute',
      '78 Synth Calliope',
      '79 Synth Bottle',
      '80 Bowed Glass',
      '81 Synth Square Lead',
      '82 Synth Spce',
      '83 Echo Drop',
      '84 Soft Pad',
      '85 E-Piano FM 2',
      '86 Dulcimer Austria',
      '87 Clavinet',
      '88 Harpsichord',
      '89 Timpani',
      '90 Celesta',
      '91 Music Box',
      '92 Tub Bell',
      '93 Harmonium',
      '94 Synth Bass 1',
      '95 Synth Bass 2',
      '96 Voice Doo',
      '97 Trumpet mute',
      '98 Englishhorn',
      '99 Cortales',
      '100 Bassoon',
      '101 Oboe',
      '102 Horn',
      '103 Piccolo',
      '105 Whistle GS',
      '106 Whistle',
      '107 Okarina',
      '108 Shani',
      '109 Shaku',
      '110 Chiffer',
      '111 Charang',
      '112 Bass & Lead',
      '113 Synth 5th',
      '114 Metal Pad',
      '115 Poly Brass Synth',
      '116 Sweep Juno',
      '117 Halo Pad',
      '118 Ice Rain',
      '119 Goblin',
      '120 Soundtrack 5',
      '121 Poly Synth',
      '122 Synth up',
      '123 Fade Synth',
      '124 Crystal',
      '125 Atmos',
      '126 Kalima',
      '127 Agogo'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s40: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Maugein - 88',
      '1 Maugein - 88',
      '2 Maugein - 88+16',
      '3 Maugein - 4+88',
      '4 Maugein - 4+88+16',
      '5 Maugein - 888',
      '6 Maugein - 888',
      '7 Maugein - 888+16',
      '8 Maugein - 4+888',
      '9 Maugein - 4+888+16',
      '10 Hohner - 88 Celeste',
      '11 Hohner - 88 Celeste',
      '12 Hohner - 88+16',
      '13 Hohner - 4+88+16',
      '14 Hohner - 816 Tango Repetition',
      '15 Hohner - 816 Tango Repetition',
      '16 Hohner - 816 Tango',
      '17 Hohner - 4+816 Tango',
      '18 Cavagnnolo - VE10 Celeste 88',
      '19 Cavagnnolo - VE10 Celeste 88',
      '20 Cavagnnolo - VE10 Celeste 88+16',
      '21 Cavagnnolo - VE10 Celeste 88+1616',
      '22 Cavagnnolo - Double Bassoon',
      '23 Cavagnnolo - Double Bassoon',
      '24 V3 888 Repetition',
      '25 V3 888 Repetition',
      '26 V3 888 Repetition Off & 1 Oct',
      '27 Mengascini - Retro 88',
      '28 Mengascini - Retro 88',
      '29 Mengascini - Retro 8888',
      '30 Mengascini - Retro 8888',
      '31 Mengascini - Retro 8888+8 Mega Musette',
      '32 Mengascini - Retro Read 8',
      '33 Mengascini - Retro Read 8',
      '34 Mengascini - Retro Read 8 - cc1',
      '35 Mengascini - Retro Read 8 - cc1',
      '36 Scandalli - Super VI Reed 8',
      '37 Scandalli - Super VI Reed 8',
      '38 Scandalli - Super VI Reed 8 - cc11',
      '39 Scandalli - Super VI 88',
      '40 Scandalli - Super VI 8+16 Repetition',
      '41 Scandalli - Super VI 4+8',
      '42 Scandalli - Super VI 4+16 Repetition',
      '43 Scandalli - Super VI 4+88',
      '44 Scandalli - Super VI 4+8+16 Repetition',
      '45 Scandalli - Super VI 4+88+ 16 Repetition',
      '46 Scandalli - Super VI 488+16 Repetition',
      '47 BAL 888',
      '48 BAL 888',
      '49 Galati Accordion - Vintage',
      '50 Galati Accordion - Vintage',
      '51 Bugari - Reed 16 Jazz',
      '52 Bugari - Reed 16 Jazz',
      '53 Bugari - 4+16',
      '54 Bugari - 8+16',
      '55 Bugari - 4+8+16',
      '56 Mengascini - 4+8 Tango',
      '57 Bugari Armando - Reed 8 Cassotto',
      '58 Bugari Armando - Reed 8 Cassotto',
      '59 Bugari Armando - Reed 8 Cassotto - cc11',
      '60 Bugari Armando - Reed 8 Cassotto - cc11',
      '61 V3 SVI & Bugari - 8+8 cassotto',
      '62 V3 SVI & Bugari - 8+8 - cc11',
      '63 V3 SVI & Bugari - 8+8 - tune+6',
      '64 V3 SVI & Pietro Mario - 8+8',
      '65 V3 SVI & Pietro Mario - 8+8',
      '66 V3 SVI & Pietro Mario - 8+8 B',
      '67 V3 SVI & Pietro Mario - 8+8 B',
      '68 V3 SVI & Pietro Mario - 8+8 tune 3',
      '69 V3 SVI & Pietro Mario - 8+8 tune 6',
      '70 V3 SVI & Pietro Mario - 8+8 tune 9',
      '71 Hohner - Morino VM 888',
      '72 Hohner - Morino VM 888',
      '73 Hohner - 888+16',
      '74 Hohner - 4+888',
      '75 Hohner - 4+888+16',
      '76 Alpengold 888',
      '77 Alpengold 888',
      '78 Hohner - Alpina 888',
      '79 Hohner - Alpina 888',
      '80 Zupan - 88',
      '81 Zupan - 88',
      '82 Zupan - Reed 8',
      '83 Zupan - Reed 8',
      '84 Zupan - Reed 8 - cc11',
      '85 Zupan - Reed 8 - cc11',
      '86 V3 888 Swinging Musette',
      '87 V3 888 Swinging Musette',
      '88 V3 888',
      '89 V3 8+16',
      '90 Alpengold Reed 4',
      '91 Hohner - Scot Gola 888',
      '92 Hohner - Scot Gola 888',
      '93 Hohner - Scot 888+16',
      '94 Hohner - Scot 4+888',
      '95 Hohner - Scot 4+888+16',
      '96 Hohner - Scot Domino VM 888',
      '97 Hohner - Domino 4816',
      '98 Hohner - Scot J-Shand 888',
      '99 Borsini Irish 888',
      '100 Pietro Mario - 88',
      '101 Pietro Mario - 88',
      '102 Pietro Mario - 88+16',
      '103 Pietro Mario - 4+88',
      '104 Pietro Mario - 4+88+16',
      '105 Pietro Mario - Reed 8',
      '106 Pietro Mario - Reed 8',
      '107 Pietro Mario - 8+16',
      '108 Pietro Mario - 8+16',
      '109 Pietro Mario - 4+8',
      '110 Pietro Mario - 4+8',
      '111 V3 8+8+8 A',
      '112 V3 8+8+8 B',
      '113 V3 8+8+8 C',
      '114 V3 8+8+8 D',
      '115 Accordiola Benelux 888',
      '116 Accordiola Benelux 888',
      '117 Accordiola 888+8 Mega',
      '118 V3 8+8+8 tune 11',
      '119 V3 8+8+8 tune 17',
      '120 V3 8+8+8 tune 23',
      '121 V3 8+8+8 tune 29',
      '122 V3 8+8+8 tune 38'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s41: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '0 Weltmeister Melodion Reed 8',
      '1 Weltmeister Melodion Reed 8',
      '2 V3 8+8+8 tune 0',
      '3 V3 8+8+8 tune 10',
      '4 V3 8+8+8 tune 20',
      '5 V3 88+8 tune 0',
      '6 V3 88+8 tune 20',
      '7 Weltmeister Melodion 888',
      '8 Weltmeister Melodion 888+8 Mega Tune',
      '9 Strasser - Steirisch II',
      '10 Alpengold Steirische',
      '11 Kaertnerland Steirische',
      '12 Kaertnerland Steirische Posch I',
      '13 Mueller - Steirische',
      '14 Hohner - Corona Vintage 888',
      '15 Brandolini Irish Melodeon',
      '16 Sernelli - Netherland Melodeon',
      '17 Victoria - Bandeon - Repetition',
      '18 Victoria - Bandeon - Repetition',
      '19 Concertina',
      '20 Nussbaumer - Schwyzeroergeli III',
      '21 Nussbaumer - Schwyzeroergeli II',
      '50 Scandalli - VI Bass',
      '51 Scandalli - VI Bass',
      '52 Victoria - Bass',
      '53 Bugari - Bass 16',
      '54 Bugari - Bass 16',
      '55 Bugari - Bass 8',
      '56 Bugari - Bass 8',
      '57 Bugari - Bass 4',
      '58 Bugari - Bass 4',
      '59 Bugari - Bass 2',
      '60 Bugari - Bass 2',
      '61 Bugari - Bass 8+16',
      '62 Bugari - Bass 8+16',
      '63 Bugari - Bass 4+8+16',
      '64 Bugari - Bass 4+8+16',
      '65 Scandalli - Bass VI + 32',
      '66 Scandalli - Bass VI + 32',
      '67 Scandalli - Chord',
      '68 Scandalli - Chord',
      '69 Bugari - Chord 4',
      '70 Bugari - Chord 4',
      '71 Bugari - Chord 8',
      '72 Bugari - Chord 8',
      '73 Bugari - Chord 4+8',
      '74 Bugari - Chord 4+8',
      '75 Bugari - Chord 2+4',
      '76 Bugari - Chord 2+4',
      '90 Weltmeister Melodion Bass',
      '91 Weltmeister Melodion Bass',
      '92 Weltmeister Melodion Chord',
      '93 Weltmeister Melodion Chord',
      '94 Alpengold - Steirische Helikon',
      '95 Alpengold - Steirische Helikon soft off',
      '96 Mueller - Steirische Bass',
      '97 Mueller - Steirische Bass',
      '98 Nussbaumer - Schwyzeroergeli Bass',
      '100 Attack Noise',
      '101 Finger Attak Noise - curve',
      '102 Attrack Bass',
      '103 Attack Chord Repetition',
      '104 Key off noise',
      '105 Reed off Musette',
      '106 Reed of Accordion'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s42: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
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
      '61 Vox IV Hawaii long'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s71: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Hohner Gol. 888',
      '2 Hohner Gol. 888+16',
      '5 Hohner Domino 888',
      '6 Hohner Domino 888+16',
      '9 Hohner Shand 888',
      '10 Hohner Shand 888+16',
      '13 Borsini 888 Irland',
      '14 Borsini 888+16 Irland',
      '17 Pietro Mario Irish 88',
      '18 Pietro Mario Irish 88-16',
      '19 Pietro Mario Irish 4-88',
      '20 Pietro Mario Irish 4-88-16',
      '21 Pietro Mario Irish 8',
      '22 Pietro Mario Irish 8-16',
      '23 Pietro Mario Irish 4-8',
      '24 Pietro Mario Irish 4-8-16',
      '25 Pietro Mario V3 8+88 wide',
      '26 Pietro Mario V3 8+88 wide dark',
      '27 Pietro Mario V3 8+88+8 wide',
      '28 Pietro Mario V3 8+88 small',
      '33 Bugari Reed 16',
      '34 Alpengold Reed 4',
      '35 Brandoni Irish tuned Melodeon 88',
      '36 Weltmeister 8+8 tune small',
      '37 Weltmeister 8+8 tune medium',
      '38 Weltmeister 8+8 tune wide',
      '39 Weltmeister 8+ Acc. 8 tune small',
      '40 Weltmeister 8+ Acc. 8 tune medium',
      '41 Weltmeister 8+ Acc. 8 tune wide',
      '43 High Whistle',
      '44 High Whistle - round robin grace notes',
      '45 High Whistle - slide up velocity 116-117',
      '46 High Whistle - grace notes'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s72: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 MQ French 88',
      '2 Hohner Tango',
      '10 Zupan Alpin 8 Reed (Cassotto)',
      '11 Zupan Alpin 8+8 tune medium',
      '12 Zupan Alpin 8+8 tune flat',
      '13 Zupan Alpin 8+8 tune small',
      '14 Zupan Alpin 8+8 tune wide',
      '15 Zupan Alpin 8+16',
      '16 Zupan Alpin 4',
      '17 MAU Musette 888',
      '21 Hohner 88',
      '23 Hohner Tango 8/16',
      '24 Hohner Tango 4+8+16',
      '25 Celest 88',
      '42 Zupan Reed 8 no Cassotto',
      '48 Scandalli VI Vintage 8',
      '49 Scandalli VI Vintage 88',
      '50 Scandalli VI 8+8 flat',
      '51 Scandalli VI 8+8 flat +',
      '52 Scandalli VI 8+8 medium',
      '53 Scandalli VI 8+8+8 medium +',
      '54 Scandalli VI 8+8 wide',
      '55 Scandalli VI 8+8 wide +',
      '66 Bugari 16 Reed',
      '67 MEN 888 Retro Musette',
      '68 BAM 8 Reed',
      '69 BAM +SCVI 8+8',
      '70 BAM +SCVI 8+8',
      '82 Hohner Corso 888 Vintage',
      '83 Weltmeister 8 Reed',
      '84 Weltmeister 8+8 small',
      '85 Weltmeister 8+8 medium',
      '86 Weltmeister 8+8 wide',
      '87 Weltmeister 8+8+8 small',
      '88 Weltmeister 8+8+8 medium',
      '89 Weltmeister 8+8+8 wide',
      '90 Weltmeister 888',
      '91 Weltmeister 888+8',
      '92 Weltmeister 8+16'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s74: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 77655678 slow'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s75: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Manolin Tremolo'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s80: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Morino VM Vinetage 888',
      '2 Morino VM Vinetage 888+16',
      '3 Morino VM Vinetage 4+888',
      '4 Morino VM Vinetage 4+888-16',
      '10 Morino VM Vinetage 888',
      '11 Alpengold Krainer 888',
      '12 Alpengold Krainer 888+16',
      '13 Alpengold Krainer 4+888',
      '14 Alpengold Krainer 4+888+16',
      '20 Alpengold Krainer 888',
      '21 Hohner Alpina 888',
      '22 Hohner Alpina 888+16',
      '23 Hohner Alpina 4+888',
      '24 Hohner Alpina 4+888+16',
      '30 Hohner Alpina 888',
      '51 Zupan Juwel 88',
      '52 Zupan Juwel 88+16',
      '53 Zupan Juwel 4+88',
      '54 Zupan Juwel 4+88+16',
      '60 Zupan Juwel 88',
      '61 Bugari 16',
      '62 Bugari 16',
      '63 Bugari 4+16',
      '64 Bugari 8+16',
      '65 Zupan 8',
      '66 Zupan 8+16',
      '67 Zupan 8+16',
      '95 M-St. Leonhard',
      '98 M-St. Leonhard',
      '101 Accordion Bass',
      '102 Accordion Bass 16',
      '103 Accordion Bass 8',
      '104 Accordion Bass 4',
      '105 Accordion Bass 2',
      '106 Accordion Bass 16+8',
      '107 Accordion Bass 16+8+4',
      '109 Accordion VI Chord',
      '110 Accordion 4',
      '111 Accordion 8',
      '112 Accordion 4+8',
      '113 Accordion 2+4',
      '114 Steirische Bass',
      '115 Steirische Bass 2',
      '116 Steirische Acc',
      '121 Steirische Helikon',
      '122 Steirische Helikon',
      '123 Key Off',
      '124 Attack Layer linear',
      '125 Attack Layer concave',
      '126 Attack Layer con offset 50'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s81: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Trompete Ivan Presern',
      '2 Trompete Ivan Presern',
      '3 Trompete Ivan Presern 1/4 Note',
      '4 Trompete Ivan Presern 1/4 Note',
      '5 Trompete Ivan Presern Staccato',
      '7 Trompete soft',
      '8 Trompete hard',
      '10 Trompete soft Slide',
      '11 Trompeten Ens. Stereo LP',
      '12 Trompeten Ens. Stereo HP',
      '13 Trompeten Ens. Stereo',
      '15 Fluegelhorn Ivan Presern',
      '19 Trompete Daempfer',
      '21 Bariton Sepp Mattlschweiger Akzent',
      '23 Bariton Sepp Mattlschweiger Vibrato',
      '24 Bariton Sepp Mattlschweiger Staccato mezzo',
      '25 Bariton Sepp Mattlschweiger Staccato forte',
      '41 Bariton Janez Per Azent',
      '43 Bariton Janez Per Vibrato',
      '44 Bariton Janez Per Staccato mezzo',
      '51 Bassposaune Global Vibrato',
      '52 Bassposaune Global Staccato',
      '55 Tenorhorn Vibrato',
      '59 French Horn',
      '61 Martin Zagrajsek Vibrato',
      '62 Martin Zagrajsek soft',
      '63 Martin Zagrajsek Slide',
      '66 Vito Muzenic Vibrato',
      '67 Vito Muzenic Vibrato',
      '68 Vito Muzenic Staccato',
      '69 Vito Muzenic Staccato',
      '70 Ensamble Clarinets',
      '71 Hackbrett 4-strings',
      '72 Hackbrett 4-strings mit Ausklang',
      '73 Hackbrett 4-strings IAK Duett Low',
      '74 Hackbrett 4-strings IAK Duett High',
      '77 Zither',
      '81 Nylon Zupfgitarre',
      '82 Nylon Zupfgitarre',
      '83 Rythmus Gitarre',
      '84 Rythmus Gitarre +',
      '85 Jazz Gitarre Castello',
      '87 Jazz Gitarre Micro',
      '88 Jazz Gitarre Amp',
      '89 Jazz Gitarre - CP - Micro',
      '90 Jazz Gitarre - CP - Amp',
      '91 Harfe',
      '92 Harfe mit Ausklang',
      '93 Harfe Arpeggio',
      '111 Geige Vibrato',
      '112 Geige Vibrato velocity Arco',
      '113 Geige Slide',
      '114 Geige Legato',
      '115 Geige Legato up',
      '116 Geige Legato down',
      '127 Maultrommel'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s82: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 E-Bass USA',
      '2 E-Bass USA',
      '3 E-Bass USA EQ1',
      '4 E-Bass USA EQ1',
      '5 E-Bass USA EQ2',
      '6 E-Bass USA EQ2',
      '9 E-Bass USA EQ3',
      '10 E-Bass USA EQ3',
      '13 E-Bass UK',
      '14 E-Bass UK',
      '17 E-Bass Pick',
      '18 E-Bass Pick',
      '21 E-Bass Pick EQ',
      '22 E-Bass Pick EQ',
      '25 E-Bass Flat',
      '26 E-Bass Flat',
      '27 E-Bass Flat EQ',
      '28 E-Bass Flat EQ',
      '37 E-Bass USA HQ',
      '51 Kontrabass T. Mihelic & Atk.',
      '52 Kontrabass T. Mihelic & Atk.',
      '53 Kontrabass T. Mihelic',
      '54 Kontrabass T. Mihelic Release',
      '61 Kontrabass 3',
      '62 Kontrabass 3 Ausklang',
      '63 Kontrabass 3 soft Attack',
      '64 Kontrabass 3 soft Attack Ausklang',
      '71 Kontrabass kurz gestichen',
      '72 Kontrabass kurz gestichen - Ausklang',
      '73 Kontrabass kurz gestichen - Ausklang +',
      '74 Kontrabass kurz gestichen - Ausklang ++'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s83: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '1 Bariton Sepp Mattlschweiger Akzent',
      '3 Bariton Sepp Mattlschweiger Vibrato',
      '4 Bariton Sepp Mattlschweiger Staccato mezzo',
      '5 Bariton Sepp Mattlschweiger Staccato forte',
      '6 Bariton Sepp Mattlschweiger EQ1 Akzent',
      '8 Bariton Sepp Mattlschweiger EQ1 Vibrato',
      '9 Bariton Sepp Mattlschweiger EQ1 Staccato mezzo',
      '10 Bariton Sepp Mattlschweiger EQ1 Staccato forte',
      '11 Bariton Sepp Mattlschweiger EQ2 Akzent',
      '13 Bariton Sepp Mattlschweiger EQ2 Vibrato',
      '14 Bariton Sepp Mattlschweiger EQ2 Staccato mezzo',
      '15 Bariton Sepp Mattlschweiger EQ2 Staccato forte',
      '31 Bariton Janez Per Akzent',
      '33 Bariton Janez Per Vibrato',
      '34 Bariton Janez Per Staccato',
      '36 Bariton Janez Per EQ1 Akzent',
      '38 Bariton Janez Per EQ1 Vibrato',
      '39 Bariton Janez Per EQ1 Staccato',
      '41 Global Bass Vibrato',
      '42 Global Bass Staccato',
      '43 EQ1 Global Bass Vibrato',
      '44 EQ1 Global Bass Staccato',
      '49 Soli Bariton Horn - Vintage',
      '51 Jon Sass Solo Tuba',
      '52 Jon Sass Solo Tuba soft',
      '56 Ensamble Tuben'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s84: TArrayOfString =
  {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
      '1 Gitarre Polka - Sabrina Klotz',
      '2 Gitarre Walzer - Sabrina Klotz',
      '3 Gitarre - Sabrina Klotz',
      '16 Gitarre Mikro Polka - Renato Verlic',
      '18 Gitarre Mikro Walzer - Renato Verlic',
      '19 Gitarre Mikro - Renato Verlic',
      '39 Git. Jazz Amp & Mikro Polka - Edi Koehldorfer',
      '40 Git. Jazz Amp & Mikro Walzer - Edi Koehldorfer',
      '41 Git. Jazz Amp & Mikro - Edi Koehldorfer',
      '101 Nylon Gitarre solw Arpeggio',
      '102 Jazz Gitarre solw Arpeggio'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s98: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '1 Xylophon',
      '2 Choir Ohh',
      '3 Choir Aah',
      '5 Cornet',
      '6 Super VI',
      '7 Reed 8',
      '8 Mueller Steirische',
      '9 Alpengold Steirische',
      '10 Hohner Alpina',
      '11 Shand Musette',
      '12 Gola Musette',
      '13 Morino VM Vintage',
      '14 High Whistle',
      '15 Accordion Celeste French',
      '16 Weltmeister Melodeon',
      '17 Accordina',
      '18 Trumpet soft',
      '19 Trumpet hard',
      '20 Trumpet Ivan',
      '21 Clarinet Vito',
      '22 Clarinet Martin',
      '23 Alen Bariton',
      '24 Sepp Bariton staccato',
      '25 Sepp Bariton Vibrato',
      '26 EB Moto',
      '27 Gitarre Global Kryner',
      '28 Gitarre Tiroler Echo',
      '29 Giterre Renato',
      '30 Alpengold Steirische',
      '31 Janez marcato',
      '32 Janez soft',
      '33 Janez staccato',
      '34 Tenorsax',
      '35 Full Strings',
      '36 Full Strings 2',
      '37 Panflute',
      '38 Flute',
      '39 Renato kurz no REPE',
      '40 Renato lang no REPE',
      '41 Mundharmonika Vib.',
      '42 Solo Posaune Ballroom',
      '43 Solo Trompete 4 Ballroom',
      '44 Solo Trompete 4 soft',
      '45 Solo Trompete 4 hard',
      '46 Solo Trompete 4 sfz',
      '47 Solo Trompete 4 legato',
      '48 Solo Jazz Sax 4 velocity split',
      '49 Solo Jazz Sax 4',
      '50 Sax Beath noise',
      '51 Klarinette Hugo Strasser',
      '52 Klarinette Martin FPC',
      '53 Klarinette Ivan FPC',
      '54 Jazz Bass - Random',
      '55 Jazz Bass - Random & noise off',
      '56 Jazz Bass no Finger noise',
      '57 Jazz Bass noise',
      '58 Fluegelhorn',
      '59 Trombone Damper',
      '60 Nussbaumer Schwyzeroergeli',
      '61 Swiss gestrichen CB',
      '101 Castello short',
      '102 Castello medium',
      '103 Castello long'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

  s99: TArrayOfString =
   {$ifdef FPC}
    (
  {$else}
    [
  {$endif}
     '1 Jimmy Smith',
      '2 Joey De Francesco',
      '3 Charles Earland',
      '4 Brian Auger',
      '5 Garner Set',
      '6 Pinao Set',
      '7 Walter Wanderley',
      '8 Whistle',
      '9 Gospel Set',
      '10 Blues Set',
      '11 Easy Listening',
      '12 Jimmy Smith',
      '13 Jimmy Smith',
      '14 Joey De Francesco',
      '15 Ballad 2',
      '16 Jesse Crawford',
      '17 Joey De Francesco',
      '18 Booker T. Jones',
      '19 Green Onions',
      '20 Matthew Fisher',
      '21 Jimmy Mc Griff Gospel',
      '22 Chords',
      '23 Chords',
      '24 Walter Wanderley',
      '25 Walter Wanderley',
      '26 Lenny Dee',
      '27 Lenny Dee',
      '28 Lenny Dee',
      '29 Ethel Smith',
      '30 Ken Griffin',
      '31 Jon Lord',
      '32 Jimmy Smith',
      '33 Jimmy Smith',
      '34 Exclusive',
      '35 Exclusive',
      '36 Standard',
      '37 Standard',
      '38 Standard',
      '39 Standard',
      '40 Standard'
  {$ifdef FPC}
    );
  {$else}
    ];
  {$endif}

var
  Banks: TBanks =
    (
        @s0, @s1, @s2, @s3, @s4, @s5, @s6, @s7,
        @s8, @s9, @s10, @s11, @s12, @s13, @s14, @s15,
        @s16, @s17, @s18, @s19, @s20, @s21, nil, @s23,
        @s24, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        @s40, @s41, @s42, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, @s71,
        @s72, nil, @s74, @s75, nil, nil, nil, nil,
        @s80, @s81, @s82, @s83, @s84, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, @s98, @s99
    );

procedure CopyBank(var Bank: TArrayOfString; Bank_: PArrayOfString);
var
  i, k: integer;
  s: string;
  b: array [0..127]of boolean;
begin
  SetLength(Bank, 0);
  if Bank_ <> nil then
    Bank := Bank_^;
  for i := 0 to 127 do
    b[i] := false;
  for i := low(Bank) to High(Bank) do
  begin
    s := Bank[i];
    if Pos(' ', s) > 0 then
      s := Copy(s, 1,Pos(' ', s));
    k := StrToIntDef(trim(s), 0);
{$ifdef CONSOLE}
    if b[k] then
      writeln('Fehler');
{$endif}
    b[k] := true;
  end;
  for i := 0 to 127 do
    if not b[i] then
    begin
      SetLength(Bank, Length(Bank)+1);
      Bank[High(Bank)] := IntToStr(i);
    end;
end;

procedure GetBank(var Bank: TArrayOfString; BankNr: integer);
var
  Bank_: PArrayOfString;
begin
  Bank_ := nil;
  if (BankNr >= 0) and (BankNr <= High(Banks)) and (Banks[BankNr] <> nil) then
    Bank_ := Banks[BankNr];
  CopyBank(Bank, Bank_);
end;

end.

// BOR
// Weltmeister Melodion


