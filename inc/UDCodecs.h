/*=============================================================================
	UDCodecs.h: UZHandler support class
	Redefined for several reasons:
		* VC.net doesn't like TArrays of unsigned types => TArray<SAFEBYTE> instead
		* Don't need the coders, only the decoders
		* Bitreader was broken => full rewrite
		* Linux UZ decompressor didn't work at all in v440/451
		* ...

	Revision history:
		* Created by AnthraX
=============================================================================*/

/*-----------------------------------------------------------------------------
	Globals
-----------------------------------------------------------------------------*/
static BYTE BitMask[8] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};

/*-----------------------------------------------------------------------------
	Definitions
-----------------------------------------------------------------------------*/
#ifdef __LINUX_X86__
	#define SAFEBYTE BYTE
#else
	#define SAFEBYTE ANSICHAR
#endif

/*-----------------------------------------------------------------------------
	FCodec base class - Redefined here. Originally in FCodec.h
-----------------------------------------------------------------------------*/
class FCodec
{
public:
	virtual UBOOL Encode( FArchive& In, FArchive& Out )=0;
	virtual UBOOL Decode( FArchive& In, FArchive& Out )=0;
};

/*-----------------------------------------------------------------------------
	FFBitReader - Simplified FBitReader. The original FBitReader was broken.
	This BitReader only works with complete bytes, unlike the original!
-----------------------------------------------------------------------------*/
#ifndef __LINUX_X86__
struct FFBitReader : public FArchive
{
public:
	FFBitReader( SAFEBYTE* Src=NULL, INT CountBits=0 )	
	:	Num			( CountBits )
	,	Buffer		( (CountBits/8) )
	,	Pos			( 0 )
	{				
		appMemcpy( &Buffer(0), Src, CountBits/8 );		
		//GLog->Logf(TEXT("Created Bitreader: %d %d"),CountBits,Buffer(0));
	}
	BYTE ReadBit()
	{
		BYTE A;		
		INT BytePos = Pos/8;
		INT InBytePos = Pos - BytePos*8;
		appMemcpy( &A, &Buffer(BytePos), 1 );
		Pos++;
		// Inverted byte order!!!!
		return ((A & BitMask[InBytePos]) != 0);
	}
	BYTE ReadByte()
	{
		BYTE A, B;
		INT BytePos = Pos/8;
		INT InBytePos = Pos - BytePos*8;		
		appMemcpy( &A, &Buffer(BytePos), 1 );
		appMemcpy( &B, &Buffer(BytePos+1), 1 );
		Pos += 8;
		// Inverted byte order!!!!
		return (A >> InBytePos) + (B << (8-InBytePos));
	}
	UBOOL AtEnd()
	{
		return (Pos == Buffer.Num()*8-1);
	}
	INT GetNumBytes()
	{
		return Buffer.Num();
	}
	INT GetNumBits()
	{
		return Buffer.Num()*8;
	}
	INT GetPosBits()
	{
		return Pos;
	}
private:
	TArray<SAFEBYTE> Buffer;
	INT   Num;
	INT   Pos;
};
#else
	#define FFBitReader FBitReader
#endif

/*-----------------------------------------------------------------------------
	FFBufferWriter - Redefined to work with SAFEBYTE (signed char) TArrays
-----------------------------------------------------------------------------*/
class FFBufferWriter : public FArchive
{
public:
	FFBufferWriter( TArray<SAFEBYTE>& InBytes )
	: Bytes( InBytes )
	, Pos( 0 )
	{
		ArIsSaving = 1;
	}
	void Serialize( void* InData, INT Length )
	{
		if( Pos+Length>Bytes.Num() )
			Bytes.Add( Pos+Length-Bytes.Num() );
		if( Length == 1 )
			Bytes(Pos) = ((BYTE*)InData)[0];
		else
			appMemcpy( &Bytes(Pos), InData, Length );
		Pos += Length;
	}
	INT Tell()
	{
		return Pos;
	}
	void Seek( INT InPos )
	{
		Pos = InPos;
	}
	INT TotalSize()
	{
		return Bytes.Num();
	}
private:
	TArray<SAFEBYTE>& Bytes;
	INT Pos;
};

/*-----------------------------------------------------------------------------
	FFBufferReader - Redefined to work with SAFEBYTE TArrays
-----------------------------------------------------------------------------*/
class FFBufferReader : public FArchive
{
public:
	FFBufferReader( const TArray<SAFEBYTE>& InBytes )
	:	Bytes	( InBytes )
	,	Pos 	( 0 )
	{
		ArIsLoading = ArIsTrans = 1;
	}
	void Serialize( void* Data, INT Num )
	{
		check(Pos>=0);
		check(Pos+Num<=Bytes.Num());
		if( Num == 1 )
			((BYTE*)Data)[0] = Bytes(Pos);
		else
			appMemcpy( Data, &Bytes(Pos), Num );
		Pos += Num;
	}
	INT Tell()
	{
		return Pos;
	}
	INT TotalSize()
	{
		return Bytes.Num();
	}
	void Seek( INT InPos )
	{
		check(InPos>=0);
		check(InPos<=Bytes.Num());
		Pos = InPos;
	}
	UBOOL AtEnd()
	{
		return Pos>=Bytes.Num();
	}
private:
	const TArray<SAFEBYTE>& Bytes;
	INT Pos;
};

/*-----------------------------------------------------------------------------
	FFCodecBWT - Burrows Wheeler Decoder
-----------------------------------------------------------------------------*/
class FFCodecBWT : public FCodec
{
private:
	/* Hand tuning suggests this is an ideal size */
	#define MAX_BUFFER_SIZE 0x40000 
	static BYTE* CompressBuffer;
	static INT CompressLength;
	static INT ClampedBufferCompare( const INT* P1, const INT* P2 )
	{
		guardSlow(FCodecBWT::ClampedBufferCompare);
		BYTE* B1 = CompressBuffer + *P1;
		BYTE* B2 = CompressBuffer + *P2;
		for( INT Count=CompressLength-Max(*P1,*P2); Count>0; Count--,B1++,B2++ )
		{
			if( *B1 < *B2 )
				return -1;
			else if( *B1 > *B2 )
				return 1;
		}
		return *P1 - *P2;
		unguardSlow;
	}
public:
	UBOOL Encode( FArchive& In, FArchive& Out )
	{
		guard(FCodecBWT::Encode);
		// Don't need this
		return 0;
		unguard;
	}
	UBOOL Decode( FArchive& In, FArchive& Out )
	{
		guard(FCodecBWT::Decode);
		TArray<SAFEBYTE> DecompressBuffer(MAX_BUFFER_SIZE+1);
		TArray<INT>  Temp(MAX_BUFFER_SIZE+1);
		INT DecompressLength, DecompressCount[256+1], RunningTotal[256+1], i, j;
		BYTE DI;
		while( !In.AtEnd() )
		{
			INT First, Last;
			In << DecompressLength << First << Last;
			GLog->Logf(TEXT("DecompressLength: %d 0x%08X"), DecompressLength);
			check(DecompressLength<=MAX_BUFFER_SIZE+1);
			check(DecompressLength<=In.TotalSize()-In.Tell());
			In.Serialize( &DecompressBuffer(0), ++DecompressLength );
			for( i=0; i<257; i++ )
				DecompressCount[ i ]=0;
			for( i=0; i<DecompressLength; i++ )
			{
				appMemcpy( &DI, &DecompressBuffer(i), 1 );
				DecompressCount[ i!=Last ? DI : 256 ]++;
			}
			INT Sum = 0;
			for( i=0; i<257; i++ )
			{
				RunningTotal[i] = Sum;
				Sum += DecompressCount[i];
				DecompressCount[i] = 0;
			}
			for( i=0; i<DecompressLength; i++ )
			{
				appMemcpy( &DI, &DecompressBuffer(i), 1 );
				INT Index = i!=Last ? DI : 256;
				Temp(RunningTotal[Index] + DecompressCount[Index]++) = i;
			}
			for( i=First,j=0 ; j<DecompressLength-1; i=Temp(i),j++ )
				Out << DecompressBuffer(i);
		}
		return 1;
		unguard;
	}
};
/*BYTE* FFCodecBWT::CompressBuffer;
INT   FFCodecBWT::CompressLength;*/

/*-----------------------------------------------------------------------------
	FFCodecRLE - Runlength Decoder
-----------------------------------------------------------------------------*/
class FFCodecRLE : public FCodec
{
private:
	enum {RLE_LEAD=5};
	UBOOL EncodeEmitRun( FArchive& Out, BYTE Char, BYTE Count )
	{
		for( INT Down=Min<INT>(Count,RLE_LEAD); Down>0; Down-- )
			Out << Char;
		if( Count>=RLE_LEAD )
			Out << Count;
		return 1;
	}
public:
	UBOOL Encode( FArchive& In, FArchive& Out )
	{
		guard(FCodecRLE::Encode);		
		return 0;
		unguard;
	}
	UBOOL Decode( FArchive& In, FArchive& Out )
	{
		guard(FCodecRLE::Decode);
		INT Count=0;
		BYTE PrevChar=0, B, C;
		SAFEBYTE A;
		while( !In.AtEnd() )
		{
			In << A;
			Out << A;
			appMemcpy( &B, &A, 1 );
			if( B!=PrevChar )
			{
				PrevChar = B;
				Count    = 1;
			}
			else if( ++Count==RLE_LEAD )
			{
				In << C;
				check(C>=2);
				while( C-->RLE_LEAD )
					Out << B;
				Count = 0;
			}
		}
		return 1;
		unguard;
	}
};

/*-----------------------------------------------------------------------------
	FFCodecHuffman - Huffman decoder
-----------------------------------------------------------------------------*/
class FFCodecHuffman : public FCodec
{
private:
	struct FHuffman
	{
		INT Ch, Count;
		TArray<FHuffman*> Child;
		TArray<SAFEBYTE> Bits;
		FHuffman( INT InCh )
		: Ch(InCh), Count(0)
		{
		}
		~FHuffman()
		{
			for( INT i=0; i<Child.Num(); i++ )
				delete Child( i );
		}
		void PrependBit( BYTE B )
		{
			Bits.Insert( 0 );
			Bits(0) = B;
			for( INT i=0; i<Child.Num(); i++ )
				Child(i)->PrependBit( B );
		}
		void WriteTable( FBitWriter& Writer )
		{
			Writer.WriteBit( Child.Num()!=0 );
			if( Child.Num() )
				for( INT i=0; i<Child.Num(); i++ )
					Child(i)->WriteTable( Writer );
			else
			{
				BYTE B = Ch;
				Writer << B;
			}
		}
		void ReadTable( FFBitReader& Reader )
		{
			if( Reader.ReadBit() )
			{
				Child.Add( 2 );
				for( INT i=0; i<Child.Num(); i++ )
				{
					Child( i ) = new FHuffman( -1 );
					Child( i )->ReadTable( Reader );
				}
			}
			else 
			{
#ifndef __LINUX_X86__
				Ch = Reader.ReadByte();
#else
				Ch = Arctor<BYTE>( Reader );
#endif
			}
		}
	};
	static QSORT_RETURN CDECL CompareHuffman( const FHuffman** A, const FHuffman** B )
	{
		return (*B)->Count - (*A)->Count;
	}
public:
	UBOOL Encode( FArchive& In, FArchive& Out )
	{
		guard(FCodecHuffman::Encode);
		
		return 0;
		unguard;
	}
	UBOOL Decode( FArchive& In, FArchive& Out )
	{
		guard(FCodecHuffman::Decode);
		INT Total;
		In << Total;
		TArray<SAFEBYTE> InArray( In.TotalSize()-In.Tell() );
		In.Serialize( (BYTE*)&InArray(0), InArray.Num() );
		FFBitReader Reader( &InArray(0), InArray.Num()*8 );
		FHuffman Root(-1);
		Root.ReadTable( Reader );

		while( Total-- > 0 )
		{
			check(!Reader.AtEnd());
			
			FHuffman* Node=&Root;
			BYTE Bit = 0;
			while (Node->Ch==-1)
			{
				Bit = Reader.ReadBit();
				Node = Node->Child(Bit);
			}			
			BYTE B = Node->Ch;
			SAFEBYTE A;
			appMemcpy( &A, &B, 1 );
			Out << A;
		}
		return 1;
		unguard;
	}
};

/*-----------------------------------------------------------------------------
	FFCodecMTF - Move to front decoder
-----------------------------------------------------------------------------*/
class FFCodecMTF : public FCodec
{
public:
	UBOOL Encode( FArchive& In, FArchive& Out )
	{
		guard(FCodecMTF::Encode);		
		return 0;
		unguard;
	}
	UBOOL Decode( FArchive& In, FArchive& Out )
	{
		guard(FCodecMTF::Decode);
		BYTE List[256], B = 0, C = 0;
		SAFEBYTE A = 0, D = 0;
		INT i;
		for( i=0; i<256; i++ )
			List[i] = i;
		while( !In.AtEnd() )
		{
			In << A;
			appMemcpy ( &B, &A, 1 );
			C = List[B];
			appMemcpy ( &D, &C, 1 );
			Out << D;
			INT NewPos=0;
			for( i=B; i>NewPos; i-- )
				List[i]=List[i-1];
			List[NewPos] = C;
		}
		return 1;
		unguard;
	}
};

/*-----------------------------------------------------------------------------
	FFCodecFull - General Purpose Decoder
-----------------------------------------------------------------------------*/
class FFCodecFull : public FCodec
{
private:
	TArray<FCodec*> Codecs;
	void Code( FArchive& In, FArchive& Out, INT Step, INT First, UBOOL (FCodec::*Func)(FArchive&,FArchive&) )
	{
		guard(FCodecFull::Code);
		TArray<SAFEBYTE> InData, OutData;
		FLOAT TotalTime=0.f;
		for( INT i=0; i<Codecs.Num(); i++ )
		{			
			FFBufferReader Reader(InData);
			FFBufferWriter Writer(OutData);
			FTime StartTime, EndTime;
			StartTime = appSeconds();
			(Codecs(First + Step*i)->*Func)( *(i ? &Reader : &In), *(i<Codecs.Num()-1 ? &Writer : &Out) );
			EndTime = appSeconds() - StartTime.GetFloat();
			TotalTime += EndTime.GetFloat();
			GWarn->Logf(TEXT("stage %d: %f secs"), i, EndTime.GetFloat() );
			GWarn->Logf(TEXT("InData size: %d - OutData size: %d"),InData.Num(),OutData.Num());
			if( i<Codecs.Num()-1 )
			{
				InData = OutData;
				OutData.Empty();
			}
		}
		GWarn->Logf(TEXT("Total: %f secs"), TotalTime );
		unguard;
	}
public:
	UBOOL Encode( FArchive& In, FArchive& Out )
	{
		guard(FCodecFull::Encode);
		Code( In, Out, 1, 0, &FCodec::Encode );
		return 0;
		unguard;
	}
	UBOOL Decode( FArchive& In, FArchive& Out )
	{
		guard(FCodecFull::Decode);
		Code( In, Out, -1, Codecs.Num()-1, &FCodec::Decode );
		return 1;
		unguard;
	}
	void AddCodec( FCodec* InCodec )
	{
		guard(FCodecFull::AddCodec);
		Codecs.AddItem( InCodec );
		unguard;
	}
	~FFCodecFull()
	{
		guard(FCodecFull::~FCodecFull);
		for( INT i=0; i<Codecs.Num(); i++ )
			delete Codecs( i );
		unguard;
	}
};

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
