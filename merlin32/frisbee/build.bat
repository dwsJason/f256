rem build frisbee.pgz
..\bin\merlin32 -v . link.s
rem make the symbols friends for FoenixIDE, if we need to debug
..\bin\mappy.exe frisbee.pgz_Output.txt > frisbee.lst
rem run the program
runpgz frisbee.pgz

