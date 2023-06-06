// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UZDownloader: This class is designed to download files off a uz master
// server. Basically a non-buffered httpclient
// =============================================================================
class UZDownloader expands TcpLink;

var UZHandler Saver;         // saves the stuff downloaded
var DownloadClient GUI;      // the GUI for this.
var int TotalSize;           // total size of the file.
var int Downloaded;          // ammount of data downloaded so far.
var float ElapsedTime;       // time taken since start of binary data
var string ServerAddr;       // server to download from
var string ServerURI;        // local directory and file on server.
var string CF;               // carriage return (chr(13)) + line feed (chr(10))
var bool bHeaderRead;        // has http header been read?
var bool bResponded;         // if got response
var string Line;             // line of data
var bool bReadyToSave;       // will save next tick (allow window time to update)
var bool bDoTick;            // set to true when the socket can be polled

// =============================================================================
// PostBeginPlay
// =============================================================================
function PostBeginPlay()
{
	CF = Chr(13)$Chr(10);
	bDoTick=false;
	Super.PostBeginPlay();
}

// =============================================================================
// Destroyed ~ Clean up!
// =============================================================================
event Destroyed()
{
	local byte B[255], i;

	// Flush socket buffers
	while (IsDataPending() && i<30)
	{
		i++;
		ReadBinary(255,B);
	}

	// Close socket
	if (IsConnected())
		close();

	// Needs to be none for GC
	Saver=none;
}

// =============================================================================
// setError ~ HTTP 404 etc
// =============================================================================
function setError(int code)
{
	GUI.setError(code);
	destroy();
}

// =============================================================================
// Setup
// =============================================================================
function Setup(DownloadClient g, string masterServer, string FName, GUID reqGUID, int reqGen)
{
	local int i;

	if (bDeleteMe)
	{
		log("error. attempted to setup a dead uzdownloader!");
		return;
	}

	GUI = g;

	// Set up native object
	Saver = new (none) class'UZHandler';
	Saver.FileGUID = reqGUID;
	Saver.FileGen  = reqGen;

	// Parse URL
	i = instr(masterServer, "/");
	if (i!=-1)
	{
		ServerURI  = mid(masterServer,i);
		ServerAddr = left(masterServer,i);
	}
	else
		ServerAddr = masterServer;

	while (right(ServerURI,1)=="/")
		ServerURI = left(ServerURI,len(ServerURI)-1);

	ServerURI = ServerURI$"/"$FName$".uz";

	Resolve(ServerAddr);
	SetTimer(30.0, false);
	disable('tick');
}

// =============================================================================
// ResolveFailed ~ :(
// =============================================================================
function ResolveFailed()
{
	setError(-3);
}

// =============================================================================
// Resolved
// =============================================================================
function Resolved( IpAddr Addr )
{
	GUI.dlSuccess(0);
	Addr.Port = 80; //force port 80 (HTTP)

	if (Addr.Addr==0)
	{
		SetError(-3);
		log ("Invalid server address?");
	}

	if( BindPort() <= 0)
	{
		SetError(-2);
		log("FAILED TO bind port");
		return;
	}

	SetTimer(20.0, false);
	Open(Addr);
}

// =============================================================================
// Opened
// =============================================================================
event Opened()
{
	SendText("GET"@ServerURI@"HTTP/1.1"$cf$"Connection: close"$cf$"Host:"@ServerAddr$":80"$cf$cf);
	GUI.dlSuccess(1);
	LinkMode     = MODE_Binary; //force!
	ReceiveMode  = RMODE_Manual;
	bDoTick      = true;
	enable('tick');
}

// =============================================================================
// Closed
// =============================================================================
event Closed()
{
	if (Saver!=none && Downloaded>0)
	{
		bReadyToSave = true;
		GUI.dlSuccess(3);
	}

	log("Download Connection Closed",'UdemoDownload');
}

// =============================================================================
// ReceivedLine ~ just for the HTTP header
// =============================================================================
event ReceivedLine( string Line )
{
	local int i, res;

	if (!bResponded)
	{
		i   = InStr(Line, " ");
		res = Int(Mid(Line, i+1));
		bResponded = true;

		if(res != 200) //200 = ok
			SetError(res);
		return;
	}

	if (Line=="")
	{
		bHeaderRead=true;
		GUI.dlSuccess(2);
		return;
	}

	if (left(Line,16)=="Content-Length: ") //size
		TotalSize = int(mid(Line,16));
}

// =============================================================================
// AddToLine ~ while waiting for the HTTP header processing to complete all
// incoming characters are added to a string...
// =============================================================================
function AddToLine (int Count, byte B[255])
{
	local int i, j;

	for (i=0;i<Count;i++)
	{
		// We might have received a part of the file already
		// => send the rest as binary
		if (bHeaderRead)
		{
			while (i<Count)
			{
				B[j]=B[i];
				j++;
				i++;
			}
			ReceivedBinary(j,B);
			return;
		}

		if (B[i] == 10 && asc(right(Line,1)) == 13)
		{
			ReceivedLine(left(Line,len(line)-1));
			Line="";

			if (bDeleteMe)
				return;
			continue;
		}

		Line=Line$Chr(B[i]);
	}
}

// =============================================================================
// Tick ~ Polls the connection
// =============================================================================
function Tick(float Delta)
{
	local byte B[255];
	local int i;

	if (bDeleteMe || !bDoTick)
		return;

	//allowed 1 tick for repainting.. now save.
	if (bReadyToSave)
	{
		Gui.SavedFile(Saver.SaveFile(!GUI.CheckCache()));
		destroy();
	}

	if (bHeaderRead)
		ElapsedTime+=Delta;

	if (ReceiveMode!=RMODE_Manual || LinkState!=STATE_Connected)
		return;

	while (IsDataPending())
	{
		i=ReadBinary(255,B);

		if (i<=0 || bDeleteMe)
			return;

		if (!bHeaderRead)
		{
			AddToLine(i,B);
			continue;
		}

		ReceivedBinary(i,B);
	}
}

// =============================================================================
// ReceivedBinary ~ byte array is just passed to the native uz saver object
// =============================================================================
event ReceivedBinary( int Count, byte B[255] )
{
	Saver.Append(Count,B);
	Downloaded+=Count;
	SetTimer(60.0, false);
}

// =============================================================================
// Timer
// =============================================================================
function Timer()
{
	SetError(-1);
	log ("Time out. Still connected?"@(!IsConnected() || !Close()));
}

defaultproperties
{
	TotalSize=-1
	LinkMode=MODE_Binary
	ReceiveMode=RMODE_Event
}
