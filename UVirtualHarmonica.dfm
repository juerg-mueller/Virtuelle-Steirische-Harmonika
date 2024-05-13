object frmVirtualHarmonica: TfrmVirtualHarmonica
  Left = 0
  Top = 0
  Width = 415
  Height = 825
  VertScrollBar.Range = 765
  VertScrollBar.Smooth = True
  VertScrollBar.Size = 100
  VertScrollBar.ThumbSize = 4
  VertScrollBar.Tracking = True
  Caption = 'Virtuelle Steirische Harmonika'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 13
  object gbMidi: TGroupBox
    Left = 0
    Top = 73
    Width = 403
    Height = 176
    Align = alTop
    Caption = 'MIDI I/O'
    TabOrder = 1
    ExplicitWidth = 399
    DesignSize = (
      403
      176)
    object lblKeyboard: TLabel
      Left = 24
      Top = 26
      Width = 37
      Height = 13
      Caption = 'MIDI IN'
    end
    object Label17: TLabel
      Left = 24
      Top = 83
      Width = 47
      Height = 13
      Caption = 'MIDI OUT'
    end
    object Label13: TLabel
      Left = 24
      Top = 55
      Width = 75
      Height = 13
      Caption = 'MIDI IN System'
    end
    object cbxMidiOut: TComboBox
      Left = 122
      Top = 80
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      OnChange = cbxMidiOutChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object cbxMidiInput: TComboBox
      Left = 122
      Top = 23
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = cbxMidiInputChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object btnReset: TButton
      Left = 122
      Top = 107
      Width = 264
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'MIDI OUT zur'#252'cksetzen'
      TabOrder = 3
      OnClick = btnResetClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object btnResetMidi: TButton
      Left = 122
      Top = 138
      Width = 264
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'MIDI Konfiguration neu laden'
      TabOrder = 4
      OnClick = btnResetMidiClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object cbxLimex: TComboBox
      Left = 122
      Top = 52
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemIndex = 0
      TabOrder = 1
      Text = 'Standard'
      OnClick = cbxLimexClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        'Standard'
        'Limex')
      ExplicitWidth = 260
    end
  end
  object gbInstrument: TGroupBox
    Left = 0
    Top = 0
    Width = 403
    Height = 73
    Align = alTop
    Caption = 'Steirische Harmonika / Aargauer'#246'rgeli'
    TabOrder = 0
    ExplicitWidth = 399
    DesignSize = (
      403
      73)
    object Label1: TLabel
      Left = 24
      Top = 33
      Width = 53
      Height = 13
      Caption = 'Instrument'
    end
    object cbTransInstrument: TComboBox
      Left = 122
      Top = 30
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = cbTransInstrumentChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
  end
  object gbRecord: TGroupBox
    Left = 0
    Top = 502
    Width = 403
    Height = 99
    Align = alTop
    Caption = 'Aufnahme'
    TabOrder = 4
    ExplicitWidth = 399
    DesignSize = (
      403
      99)
    object btnRecordIn: TButton
      Left = 122
      Top = 24
      Width = 264
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      BiDiMode = bdLeftToRight
      Caption = 'MIDI IN Aufnahme starten'
      Enabled = False
      ParentBiDiMode = False
      TabOrder = 0
      OnClick = btnRecordInClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object btnRecordOut: TButton
      Left = 122
      Top = 55
      Width = 264
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'MIDI OUT Aufnahme starten'
      TabOrder = 1
      OnClick = btnRecordOutClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
  end
  object gbMidiInstrument: TGroupBox
    Left = 0
    Top = 249
    Width = 403
    Height = 117
    Align = alTop
    Caption = 'MIDI Instrument'
    TabOrder = 2
    ExplicitWidth = 399
    DesignSize = (
      403
      117)
    object Label3: TLabel
      Left = 24
      Top = 54
      Width = 53
      Height = 13
      Caption = 'Instrument'
    end
    object Label4: TLabel
      Left = 24
      Top = 26
      Width = 23
      Height = 13
      Caption = 'Bank'
    end
    object lbVolDiskant: TLabel
      Left = 24
      Top = 82
      Width = 51
      Height = 13
      Caption = 'Lautst'#228'rke'
    end
    object cbxMidiDiskant: TComboBox
      Left = 122
      Top = 51
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 30
      ItemIndex = 21
      TabOrder = 1
      Text = '22 Accordion'
      OnChange = cbxMidiDiskantChange
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
      ExplicitWidth = 260
    end
    object cbxDiskantBank: TComboBox
      Left = 122
      Top = 23
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 20
      ItemIndex = 0
      TabOrder = 0
      Text = '00 - General Midi'
      OnChange = cbxDiskantBankChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        '00 - General Midi'
        '01 - Piano'
        '02 - E-Piano'
        '03 - Organ'
        '04 - Organ - Drawbar Registrations'
        '05 - Perc. Tuned Instr.'
        '06 - String Instr.'
        '07 - Guitar'
        '08 - Harmonica and more'
        '09 - Full Strings & Disco Strings'
        '10 - Solo Strings'
        '11 - Synth Strings'
        '12 - Brass Solo'
        '13 - Brass Section'
        '14 - Classic Brass'
        '15 - Saxophon'
        '16 - Winds'
        '17 - Classic Winds'
        '18 - Choir'
        '19 - Bass'
        '20 - Synthesizer'
        '21 - FX und Percussion'
        '22'
        '23'
        '24'
        '25'
        '26'
        '27'
        '28'
        '29'
        '30'
        '31'
        '32'
        '33'
        '34'
        '35'
        '36'
        '37'
        '38'
        '39'
        '40 - Accordion French, German, Slvenia and others'
        '41 - Bass and Chord Melo.'
        '42 - Cordovox'
        '43'
        '44'
        '45'
        '46'
        '47'
        '48'
        '49'
        '50'
        '51'
        '52'
        '53'
        '54'
        '55'
        '56'
        '57'
        '58'
        '59'
        '60'
        '61'
        '62'
        '63'
        '64'
        '65'
        '66'
        '67'
        '68'
        '69'
        '70')
      ExplicitWidth = 260
    end
    object sbVolDiscant: TScrollBar
      Left = 122
      Top = 80
      Width = 264
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Max = 120
      Min = 20
      PageSize = 0
      Position = 100
      TabOrder = 2
      OnChange = sbVolChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
  end
  object gbMidiBass: TGroupBox
    Left = 0
    Top = 366
    Width = 403
    Height = 136
    Align = alTop
    Caption = 'MIDI Bass'
    TabOrder = 3
    ExplicitWidth = 399
    DesignSize = (
      403
      136)
    object Label5: TLabel
      Left = 24
      Top = 74
      Width = 53
      Height = 13
      Caption = 'Instrument'
    end
    object Label6: TLabel
      Left = 24
      Top = 46
      Width = 23
      Height = 13
      Caption = 'Bank'
    end
    object Label7: TLabel
      Left = 24
      Top = 21
      Width = 67
      Height = 13
      Caption = 'Bass getrennt'
    end
    object lbVolBass: TLabel
      Left = 24
      Top = 102
      Width = 51
      Height = 13
      Caption = 'Lautst'#228'rke'
    end
    object cbxInstrBass: TComboBox
      Left = 122
      Top = 71
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 30
      Enabled = False
      ItemIndex = 21
      TabOrder = 2
      Text = '22 Accordion'
      OnChange = cbxMidiDiskantChange
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
      ExplicitWidth = 260
    end
    object cbxBankBass: TComboBox
      Left = 122
      Top = 43
      Width = 264
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 20
      Enabled = False
      ItemIndex = 0
      TabOrder = 1
      Text = '00 - General Midi'
      OnChange = cbxDiskantBankChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        '00 - General Midi'
        '01 - Piano'
        '02 - E-Piano'
        '03 - Organ'
        '04 - Organ - Drawbar Registrations'
        '05 - Perc. Tuned Instr.'
        '06 - String Instr.'
        '07 - Guitar'
        '08 - Harmonica and more'
        '09 - Full Strings & Disco Strings'
        '10 - Solo Strings'
        '11 - Synth Strings'
        '12 - Brass Solo'
        '13 - Brass Section'
        '14 - Classic Brass'
        '15 - Saxophon'
        '16 - Winds'
        '17 - Classic Winds'
        '18 - Choir'
        '19 - Bass'
        '20 - Synthesizer'
        '21 - FX und Percussion'
        '22'
        '23'
        '24'
        '25'
        '26'
        '27'
        '28'
        '29'
        '30'
        '31'
        '32'
        '33'
        '34'
        '35'
        '36'
        '37'
        '38'
        '39'
        '40 - Accordion French, German, Slvenia and others'
        '41 - Bass and Chord Melo.'
        '42 - Cordovox'
        '43'
        '44'
        '45'
        '46'
        '47'
        '48'
        '49'
        '50'
        '51'
        '52'
        '53'
        '54'
        '55'
        '56'
        '57'
        '58'
        '59'
        '60'
        '61'
        '62'
        '63'
        '64'
        '65'
        '66'
        '67'
        '68'
        '69'
        '70')
      ExplicitWidth = 260
    end
    object cbxBassDifferent: TCheckBox
      Left = 122
      Top = 20
      Width = 25
      Height = 17
      TabOrder = 0
      OnClick = cbxBassDifferentClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object sbVolBass: TScrollBar
      Left = 122
      Top = 98
      Width = 264
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Min = 20
      PageSize = 0
      Position = 100
      TabOrder = 3
      OnChange = sbVolChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
  end
  object gbSzene: TGroupBox
    Left = 0
    Top = 785
    Width = 403
    Height = 93
    Align = alTop
    Caption = 'Scene'
    TabOrder = 5
    ExplicitWidth = 399
    DesignSize = (
      403
      93)
    object Label9: TLabel
      Left = 32
      Top = 29
      Width = 83
      Height = 13
      Caption = 'Accordion Master'
    end
    object cbxScene: TComboBox
      Left = 122
      Top = 52
      Width = 264
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      ItemIndex = 0
      TabOrder = 0
      OnChange = cbAccordionMasterClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        ''
        'Oberkrainer')
      ExplicitWidth = 260
    end
    object cbAccordionMaster: TCheckBox
      Left = 122
      Top = 28
      Width = 25
      Height = 17
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = cbAccordionMasterClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
  end
  object gbHeader: TGroupBox
    Left = 0
    Top = 601
    Width = 403
    Height = 184
    Align = alTop
    Caption = 'Taktangaben'
    TabOrder = 6
    ExplicitWidth = 399
    DesignSize = (
      403
      184)
    object Label8: TLabel
      Left = 24
      Top = 32
      Width = 21
      Height = 13
      Caption = 'Takt'
    end
    object Label12: TLabel
      Left = 24
      Top = 59
      Width = 84
      Height = 13
      Caption = 'Viertel pro Minute'
    end
    object Label2: TLabel
      Left = 24
      Top = 115
      Width = 48
      Height = 13
      Caption = 'Metronom'
    end
    object lbBegleitung: TLabel
      Left = 24
      Top = 95
      Width = 51
      Height = 13
      Caption = 'Lautst'#228'rke'
    end
    object Label10: TLabel
      Left = 24
      Top = 135
      Width = 41
      Height = 13
      Caption = 'Nur Takt'
    end
    object Label11: TLabel
      Left = 24
      Top = 155
      Width = 60
      Height = 13
      Caption = 'Ohne Blinker'
    end
    object cbxViertel: TComboBox
      Left = 198
      Top = 29
      Width = 70
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 1
      Text = 'Viertel'
      OnChange = cbxViertelChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        'Viertel'
        'Achtel')
    end
    object cbxTakt: TComboBox
      Left = 122
      Top = 29
      Width = 70
      Height = 21
      Style = csDropDownList
      ItemIndex = 2
      TabOrder = 0
      Text = '4'
      OnChange = cbxTaktChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      Items.Strings = (
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8'
        '9'
        '10'
        '11'
        '12')
    end
    object edtBPM: TEdit
      Left = 122
      Top = 56
      Width = 70
      Height = 21
      Alignment = taRightJustify
      TabOrder = 2
      Text = '120'
      OnExit = edtBPMExit
      OnKeyPress = edtBPMKeyPress
    end
    object cbxMetronom: TCheckBox
      Left = 122
      Top = 114
      Width = 25
      Height = 17
      TabOrder = 4
      OnClick = cbxMetronomClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object sbMetronom: TScrollBar
      Left = 122
      Top = 91
      Width = 264
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Max = 120
      Min = 20
      PageSize = 0
      Position = 80
      TabOrder = 3
      OnChange = sbVolChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
      ExplicitWidth = 260
    end
    object cbxNurTakt: TCheckBox
      Left = 122
      Top = 134
      Width = 25
      Height = 17
      TabOrder = 5
      OnClick = cbxNurTaktClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object cbxOhneBlinker: TCheckBox
      Left = 122
      Top = 154
      Width = 25
      Height = 17
      Checked = True
      State = cbChecked
      TabOrder = 6
      OnClick = cbxOhneBlinkerClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
  end
  object SaveDialog1: TSaveDialog
    FileName = 'Aufnahme.mid'
    Filter = 'MIDI|*.mid'
    InitialDir = '.'
    Left = 40
    Top = 240
  end
end
