rem build xmas.pgz
..\bin\merlin32 -v . link.s
rem make the symbols friends for FoenixIDE, if we need to debug
..\bin\mappy.exe xmas.pgz_Output.txt > xmas.lst
rem run the program
runpgz xmas.pgz

