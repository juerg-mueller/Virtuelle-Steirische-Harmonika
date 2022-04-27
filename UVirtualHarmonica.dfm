object frmVirtualHarmonica: TfrmVirtualHarmonica
  Left = 0
  Top = 0
  ActiveControl = cbxTransInstrument
  Caption = 'Virtuelle Steirische Harmonika'
  ClientHeight = 360
  ClientWidth = 440
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object gbMidi: TGroupBox
    Left = 0
    Top = 105
    Width = 440
    Height = 188
    Align = alTop
    Caption = 'MIDI'
    TabOrder = 1
    object lblKeyboard: TLabel
      Left = 25
      Top = 34
      Width = 83
      Height = 13
      Caption = 'Sustain Pedal (in)'
    end
    object Label17: TLabel
      Left = 25
      Top = 67
      Width = 83
      Height = 13
      Caption = 'Synthesizer (out)'
    end
    object lbVirtual: TLabel
      Left = 25
      Top = 101
      Width = 92
      Height = 13
      Caption = 'Virtual Device (out)'
    end
    object Label3: TLabel
      Left = 25
      Top = 136
      Width = 79
      Height = 13
      Caption = 'MIDI Instrument'
    end
    object cbxMidiOut: TComboBox
      Left = 122
      Top = 64
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbxMidiOutChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object cbxMidiInput: TComboBox
      Left = 122
      Top = 31
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbxMidiInputChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object btnResetMidi: TButton
      Left = 310
      Top = 62
      Width = 100
      Height = 25
      Caption = 'Reset Synth.'
      TabOrder = 2
      OnClick = btnResetMidiClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object cbxVirtual: TComboBox
      Left = 122
      Top = 98
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 3
      OnChange = cbxVirtualChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object cbxMidiInstrument: TComboBox
      Left = 122
      Top = 133
      Width = 303
      Height = 21
      ItemIndex = 21
      TabOrder = 4
      Text = '22 Accordion'
      OnChange = cbxMidiInstrumentChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        '1 Acoustic Grand Piano (Fl'#252'gel)'
        '2 Bright Acoustic Piano (Klavier)'
        '3 Electric Grand Piano'
        '4 Honky-tonk'
        '5 Electric Piano 1 (Rhodes)'
        '6 Electric Piano 2 (Chorus)'
        '7 Harpsichord (Cembalo)'
        '8 Clavi (Clavinet)'
        '9 Celesta'
        '10 Glockenspiel'
        '11 Music Box (Spieluhr)'
        '12 Vibraphone'
        '13 Marimba'
        '14 Xylophone'
        '15 Tubular Bells (R'#246'hrenglocken)'
        '16 Dulcimer (Hackbrett)'
        '17 Drawbar Organ (Hammond)'
        '18 Percussive Organ'
        '19 Rock Organ'
        '20 Church Organ (Kirchenorgel)'
        '21 Reed Organ (Drehorgel)'
        '22 Accordion'
        '23 Harmonica'
        '24 Tango Accordion (Bandeon)'
        '25 Acoustic Guitar (Nylon)'
        '26 Acoustic Guitar (Steel - Stahl)'
        '27 Electric Guitar (Jazz)'
        '28 Electric Guitar (clean - sauber)'
        '29 Electric Guitar (muted - ged'#228'mpft)'
        '30 Overdriven Guitar ('#252'bersteuert)'
        '31 Distortion Guitar (verzerrt)'
        '32 Guitar harmonics (Harmonien)'
        '33 Acoustic Bass'
        '34 Electric Bass (finger)'
        '35 Electric Bass (pick - gezupft)'
        '36 Fretless Bass (bundloser Bass)'
        '37 Slap Bass 1'
        '38 Slap Bass 2'
        '39 Synth Bass 1'
        '40 Synth Bass 2'
        '41 Violin (Violine - Geige)'
        '42 Viola (Viola - Bratsche)'
        '43 Cello (Violoncello - Cello)'
        '44 Contrabass (Violone - Kontrabass)'
        '45 Tremolo Strings'
        '46 Pizzicato Strings'
        '47 Orchestral Harp (Harfe)'
        '48 Timpani (Pauke)'
        '49 String Ensemble 1'
        '50 String Ensemble 2'
        '51 SynthString 1'
        '52 SynthString 2'
        '53 Choir Aahs'
        '54 Voice Oohs'
        '55 Synth Voice'
        '56 Orchestra Hit'
        '57 Trumpet (Trompete)'
        '58 Trombone (Posaune)'
        '59 Tuba'
        '60 Muted Trumpet (ged'#228'mpfe Trompete)'
        '61 French Horn (franz'#246'sisches Horn)'
        '62 Brass Section (Bl'#228'sersatz)'
        '63 SynthBrass 1'
        '64 SynthBrass 2'
        '65 Soprano Sax'
        '66 Alto Sax'
        '67 Tenor Sax'
        '68 Baritone Sax'
        '69 Oboe'
        '70 English Horn'
        '71 Bassoon (Fagott)'
        '72 Clarinet'
        '73 Piccolo'
        '74 Flute (Fl'#246'te)'
        '75 Recorder (Blockfl'#246'te)'
        '76 Pan Flute'
        '77 Blown Bottle'
        '78 Shakuhachi'
        '79 Whistle (Pfeifen)'
        '80 Ocarina'
        '81 Square (Rechteck)'
        '82 Sawtooth (S'#228'gezahn)'
        '83 Calliop'
        '84 Chiff'
        '85 Charang'
        '86 Voice'
        '87 Fifths'
        '88 Bass + Lead'
        '89 New Age'
        '90 Warm'
        '91 Polysynth'
        '92 Choir'
        '93 Bowed (Streicher)'
        '94 Metallic'
        '95 Halo'
        '96 Sweep'
        '97 Rain (Regen)'
        '98 Soundtrack'
        '99 Crystal'
        '100 Atmosphere'
        '101 Brightness'
        '102 Goblins'
        '103 Echoes'
        '104 Sci-Fi (Science Fiction)'
        '105 Sitar Ethnik'
        '106 Banjo'
        '107 Shamisen'
        '108 Koto'
        '109 Kalimba'
        '110 Bag Pipe (Dudelsack)'
        '111 Fiddle'
        '112 Shanai'
        '113 Tinkle Bell (Glocke)'
        '114 Agogo'
        '115 Steel Drums'
        '116 Woodblock'
        '117 Taiko Drum'
        '118 Melodic Tom'
        '119 Synth Drum'
        '120 Reverse Cymbal (Becken r'#252'ckw'#228'rts)'
        '121 Guitar Fret. Noise (Gitarrensaitenquitschen)'
        '122 Breath Noise (Atem)'
        '123 Seashore (Meeresbrandung)'
        '124 Bird Tweet (Vogelgezwitscher)'
        '125 Telephone Ring'
        '126 Helicopter'
        '127 Applause'
        '128 Gun Shot (Gewehrschuss)')
    end
  end
  object gbInstrument: TGroupBox
    Left = 0
    Top = 0
    Width = 440
    Height = 105
    Align = alTop
    Caption = 'Steirische Harmonika / Schwyzer'#246'rgeli'
    TabOrder = 0
    object Label13: TLabel
      Left = 24
      Top = 64
      Width = 92
      Height = 13
      Caption = 'Transpose (Primes)'
    end
    object Label1: TLabel
      Left = 25
      Top = 33
      Width = 53
      Height = 13
      Caption = 'Instrument'
    end
    object cbxTransInstrument: TComboBox
      Left = 122
      Top = 61
      Width = 46
      Height = 21
      Style = csDropDownList
      ItemIndex = 11
      TabOrder = 0
      Text = '0'
      OnChange = cbxTransInstrumentChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        '-11'
        '-10'
        '-9'
        '-8'
        '-7'
        '-6'
        '-5'
        '-4'
        '-3'
        '-2'
        '-1'
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8'
        '9'
        '10'
        '11')
    end
    object cbTransInstrument: TComboBox
      Left = 122
      Top = 30
      Width = 156
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 1
      Text = 'B-'#214'rgeli'
      OnChange = cbTransInstrumentChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        'B-'#214'rgeli'
        'A-'#214'rgeli')
    end
  end
  object gbBalg: TGroupBox
    Left = 0
    Top = 293
    Width = 440
    Height = 64
    Align = alTop
    Caption = 'Shift Button for Push/Pull'
    TabOrder = 2
    object Label2: TLabel
      Left = 25
      Top = 26
      Width = 58
      Height = 13
      Caption = 'Shift is Push'
    end
    object cbxShiftIsPush: TCheckBox
      Left = 122
      Top = 25
      Width = 15
      Height = 17
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = cbxShiftIsPushClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
  end
end
