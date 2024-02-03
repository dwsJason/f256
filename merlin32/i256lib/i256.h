/*
	I256 Access Library
	
	C Header File, for mos-llvm
	
	int is only 16 bits
	pointers are only 16 bits
	
	We deal with system memory pointers, which need 24 bits
	so going to try to just make them long
*/

u16 i256DecompressCLUT(u24 pTarget, u24 pI256);
u16 i256GetClutIO(u8* pTarget, u24 pI256);
u24 i256DecompressMAP(u24 pTarget, u16 nameAdjust, u24 pI256);
u24 i256DecompressPIXELS(u24 pTarget, u24 pI256);
u16 i256GetMapWidthHeight(u24 pI256);
u16 i256GetPixelWidth(u24 pI256);
u16 i256GetPixelHeight(u24 pI256);
u24 lzsa2Decompress(u24 pTarget, u24 pSource);

