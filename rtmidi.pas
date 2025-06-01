unit RtMidi;

interface

{$IFDEF MSWINDOWS}
uses Windows,
{$ELSE}
uses dynlibs,
{$ENDIF}
  UFormHelper, SysUtils, Classes;


const
  libName =
	{$IFDEF MSWINDOWS} 'rtmidi.dll';     {$ENDIF}
	{$IFDEF LINUX}     'librtmidi.so';   {$ENDIF}
	{$IFDEF darwin}     'librtmidi.dylib';{$ENDIF}

type
	// Wraps an RtMidi object for C function return statuses.
	TRtMidiWrapper = record
		// The wrapped RtMidi object.
		ptr, data: Pointer; // void*
		// True when the last function call was OK. 
		ok: Boolean;
		// If an error occured (ok != true), set to an error message.
		msg: PChar; // const char*
	end;
	PRtMidiWrapper = ^TRtMidiWrapper;

  uInt = cardinal;


	RtMidiPtr = PRtMidiWrapper;
	RtMidiInPtr = PRtMidiWrapper;
	RtMidiOutPtr = PRtMidiWrapper;

  // MIDI API specifier arguments.  See RtMidi::Api.
	RtMidiApi = (
		RTMIDI_API_UNSPECIFIED,    // Search for a working compiled API.
		RTMIDI_API_MACOSX_CORE,    // Macintosh OS-X CoreMIDI API.
		RTMIDI_API_LINUX_ALSA,     // The Advanced Linux Sound Architecture API.
		RTMIDI_API_UNIX_JACK,      // The Jack Low-Latency MIDI Server API.
		RTMIDI_API_WINDOWS_MM,     // The Microsoft Multimedia MIDI API.
		RTMIDI_API_RTMIDI_DUMMY,   // A compilable but non-functional API.
		RTMIDI_API_NUM             // Number of values in this enum.
	);

	// Defined RtMidiError types. See RtMidiError::Type.
	RtMidiErrorType = (
		RTMIDI_ERROR_WARNING,           // A non-critical error.
		RTMIDI_ERROR_DEBUG_WARNING,     // A non-critical error which might be useful for debugging.
		RTMIDI_ERROR_UNSPECIFIED,       // The default, unspecified error type.
		RTMIDI_ERROR_NO_DEVICES_FOUND,  // No devices found on system.
		RTMIDI_ERROR_INVALID_DEVICE,    // An invalid device ID was specified.
		RTMIDI_ERROR_MEMORY_ERROR,      // An error occured during memory allocation.
		RTMIDI_ERROR_INVALID_PARAMETER, // An invalid parameter was specified to a function.
		RTMIDI_ERROR_INVALID_USE,       // The function was called incorrectly.
		RTMIDI_ERROR_DRIVER_ERROR,      // A system driver error occured.
		RTMIDI_ERROR_SYSTEM_ERROR,      // A system error occured.
		RTMIDI_ERROR_THREAD_ERROR       // A thread error occured.
	);

	size_t = QWord;

	// The type of a RtMidi callback function.
	// * timeStamp:  The time at which the message has been received.
	// * message:    The midi message.
	// * userData:   Additional user data for the callback.
	// See RtMidiIn::RtMidiCallback.
	//
	RtMidiCCallback = procedure(timeStamp: Double; msg: PAnsiChar; messageSize: size_t; userData: Pointer);

//==========================================================================
// RtMidi API
//==========================================================================

// Determine the available compiled MIDI APIs.
// If the given 'apis' parameter is null, returns the number of available APIs.
// Otherwise, fill the given apis array with the RtMidi::Api values.
// * apis:      An array or a null value.
// * apis_size: Number of elements pointed to by apis
// Returns number of items needed for apis array if apis==NULL, or
// number of items written to apis array otherwise.
// A negative return value indicates an error.
// See RtMidi::getCompiledApi().
//
PRtMidiApi = ^RtMidiApi;
Trtmidi_get_compiled_api = function (apis: PRtMidiApi; apis_size: UInt): Integer;
  cdecl;

// Return the name of a specified compiled MIDI API.
// See RtMidi::getApiName().
//
Trtmidi_api_name = function (api: RtMidiApi): PAnsiChar;
  cdecl;

// Return the display name of a specified compiled MIDI API.
// See RtMidi::getApiDisplayName().
//
Trtmidi_api_display_name = function (api: RtMidiApi): PAnsiChar;
  cdecl;

// Return the compiled MIDI API having the given name.
// See RtMidi::getCompiledApiByName().
//
Trtmidi_compiled_api_by_name = function (name: PAnsiChar): RtMidiApi;
  cdecl;

// Report an error.
//
Trtmidi_error = procedure (errortype: RtMidiErrorType; errorString: PAnsiChar);
  cdecl;

// Open a MIDI port.
// * port:      Must be greater than 0
// * portName:  Name for the application port.
// See RtMidi::openPort().
//
Trtmidi_open_port = procedure (device: RtMidiPtr; portNumber: UInt; portName: PAnsiChar);
  cdecl;

// Creates a virtual MIDI port to which other software applications can connect.  
// portName: Name for the application port.
// See RtMidi::openVirtualPort().
//
Trtmidi_open_virtual_port = procedure (device: RtMidiPtr; portName: PAnsiChar);
  cdecl;

// Close a MIDI connection.
// See RtMidi::closePort().
//
Trtmidi_close_port = procedure (device: RtMidiPtr);
  cdecl;

// Return the number of available MIDI ports.
// See RtMidi::getPortCount().
//
Trtmidi_get_port_count = function (device: RtMidiPtr): UInt;
  cdecl;

// Return a string identifier for the specified MIDI input port number.
// See RtMidi::getPortName().

Trtmidi_get_port_name = function (device: RtMidiPtr; portNumber: UInt; name: PChar; var len: integer): PAnsiChar;
  cdecl;

//==========================================================================
// RtMidiIn API
//==========================================================================

// Create a default RtMidiInPtr value, with no initialization.
//
Trtmidi_in_create_default = function : RtMidiInPtr;
  cdecl;

// Create a  RtMidiInPtr value, with given api, clientName and queueSizeLimit.
// api            An optional API id can be specified.
// clientName     An optional client name can be specified. This
//                       will be used to group the ports that are created
//                       by the application.
// queueSizeLimit An optional size of the MIDI input queue can be
//                       specified.
// See RtMidiIn::RtMidiIn().
//
Trtmidi_in_create = function  (api: RtMidiApi; clientName: PAnsiChar; queueSizeLimit: UInt): RtMidiInPtr;
  cdecl;

// Free the given RtMidiInPtr.
//
Trtmidi_in_free = procedure (device: RtMidiInPtr);

// Returns the MIDI API specifier for the given instance of RtMidiIn.
// See RtMidiIn::getCurrentApi().
//
Trtmidi_in_get_current_api = function (device: RtMidiPtr): RtMidiApi;
  cdecl;

// Set a callback function to be invoked for incoming MIDI messages.
// See RtMidiIn::setCallback().
//
Trtmidi_in_set_callback = procedure (device: RtMidiInPtr; callback: RtMidiCCallback; userData: Pointer);
  cdecl;

// Cancel use of the current callback function (if one exists).
// See RtMidiIn::cancelCallback().
//
Trtmidi_in_cancel_callback = procedure (device: RtMidiInPtr);
  cdecl;

// Specify whether certain MIDI message types should be queued or ignored during input.
// See RtMidiIn::ignoreTypes().
//
Trtmidi_in_ignore_types = procedure (device: RtMidiInPtr; midiSysex, midiTime, midiSense: Boolean);
  cdecl;

// Fill the user-provided array with the data bytes for the next available
//MIDI message in the input queue and return the event delta-time in seconds.
// message:   Must point to a char* that is already allocated.
//                 SYSEX messages maximum size being 1024, a statically
//                 allocated array could be sufficient. 
// size:      Is used to return the size of the message obtained. 
// See RtMidiIn::getMessage().
//
Trtmidi_in_get_message = function (device: RtMidiInPtr; msg: PAnsiChar; size: size_t): Double;
  cdecl;

//==========================================================================
// RtMidiOut API
//==========================================================================

// Create a default RtMidiOutPtr value, with no initialization.
//
Trtmidi_out_create_default = function : RtMidiOutPtr;
  cdecl;

// Create a RtMidiOutPtr value, with given and clientName.
// api            An optional API id can be specified.
// clientName     An optional client name can be specified. This
//                       will be used to group the ports that are created
//                       by the application.
// See RtMidiOut::RtMidiOut().
//
Trtmidi_out_create = function (api: RtMidiApi; clientName: PAnsiChar): RtMidiOutPtr;
  cdecl;

// Free the given RtMidiOutPtr.
//
Trtmidi_out_free = procedure (device: RtMidiOutPtr);
  cdecl;

// Returns the MIDI API specifier for the given instance of RtMidiOut.
// See RtMidiOut::getCurrentApi().
//
Trtmidi_out_get_current_api = function (device: RtMidiPtr): RtMidiApi;
  cdecl;

// Immediately send a single message out an open MIDI output port.
// See RtMidiOut::sendMessage().
//
Trtmidi_out_send_message = function (device: RtMidiOutPtr; msg: PAnsiChar; length: Integer): Integer;
  cdecl;

var
  rtmidi_get_compiled_api: Trtmidi_get_compiled_api = nil;

  rtmidi_in_create: Trtmidi_in_create = nil;
  rtmidi_in_free: Trtmidi_in_free = nil;
  rtmidi_in_set_callback: Trtmidi_in_set_callback = nil;
  rtmidi_in_cancel_callback: Trtmidi_in_cancel_callback = nil;

  rtmidi_out_create: Trtmidi_out_create = nil;
  rtmidi_out_free: Trtmidi_out_free = nil;
  rtmidi_out_send_message: Trtmidi_out_send_message = nil;

  rtmidi_open_port: Trtmidi_open_port = nil;
  rtmidi_close_port: Trtmidi_close_port = nil;
  rtmidi_open_virtual_port: Trtmidi_open_virtual_port = nil;
  rtmidi_get_port_count: Trtmidi_get_port_count = nil;
  rtmidi_get_port_name: Trtmidi_get_port_name = nil;

implementation

var
  hndLib: TLibHandle = 0;

initialization

  hndLib := LoadLibrary(libName);
  if hndLib <> NilHandle then
  begin
    rtmidi_get_compiled_api :=  Trtmidi_get_compiled_api (GetProcedureAddress(hndLib, 'rtmidi_get_compiled_api'));

    rtmidi_open_port :=  Trtmidi_open_port (GetProcedureAddress(hndLib, 'rtmidi_open_port'));
    rtmidi_close_port :=  Trtmidi_close_port(GetProcedureAddress(hndLib, 'rtmidi_close_port'));
    rtmidi_open_virtual_port :=  Trtmidi_open_virtual_port(GetProcedureAddress(hndLib, 'rtmidi_open_virtual_port'));
    rtmidi_get_port_count :=  Trtmidi_get_port_count(GetProcedureAddress(hndLib, 'rtmidi_get_port_count'));
    rtmidi_get_port_name :=  Trtmidi_get_port_name(GetProcedureAddress(hndLib, 'rtmidi_get_port_name'));

    rtmidi_in_create :=  Trtmidi_in_create(GetProcedureAddress(hndLib, 'rtmidi_in_create'));
    rtmidi_in_free :=  Trtmidi_in_free(GetProcedureAddress(hndLib, 'rtmidi_in_free'));
    rtmidi_in_set_callback :=  Trtmidi_in_set_callback(GetProcedureAddress(hndLib, 'rtmidi_in_set_callback'));
    rtmidi_in_cancel_callback :=  Trtmidi_in_cancel_callback(GetProcedureAddress(hndLib, 'rtmidi_in_cancel_callback'));

    rtmidi_out_create :=  Trtmidi_out_create(GetProcedureAddress(hndLib, 'rtmidi_out_create'));
    rtmidi_out_free :=  Trtmidi_out_free(GetProcedureAddress(hndLib, 'rtmidi_out_free'));
    rtmidi_out_send_message :=  Trtmidi_out_send_message(GetProcedureAddress(hndLib, 'rtmidi_out_send_message'));
  end else begin
{$ifdef CONSOLE}
    writeln('rtmidi library "' + libName + '" not found');
{$else}
    ErrMessage('rtmidi library "' + libName + '" not found');
{$endif}
  end;

finalization

  FreeLibrary(hndLib);

end.
