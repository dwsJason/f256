rem build frisbee.pgz
..\bin\merlin32 -v . link.s
rem make the symbols friends for FoenixIDE, if we need to debug
..\bin\mappy.exe platform.pgz_Output.txt > platform.lst
rem run the program
runpgz platform.pgz

