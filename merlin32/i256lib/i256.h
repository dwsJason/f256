/*
	I256 Access Library
	
	C Header File, for mos-llvm
	
	int is only 16 bits
	pointers are only 16 bits
	
	We deal with system memory pointers, which need 24 bits
	so going to try to just make them long
*/

int i256DecompressCLUT(u24 pI256);
int i256DecompressMAP(u24 pI256, unsigned int Name, unsigned long pMemory, unsigned long ;
int i256DecompressPIXELS(unsigned long pMemory, unsigned long pI256);
int i256GetMapWidthHeight(unsigned long pI256);
int i256GetPixelWidth(unsigned long pI256);
int i256GetPixelHeight(unsigned long pI256);

