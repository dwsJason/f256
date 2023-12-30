rem build xmas.pgz
..\bin\merlin32 -v . link.s
rem make the symbols friends for FoenixIDE, if we need to debug
..\bin\mappy.exe modojr.pgz_Output.txt > modojr.lst
rem run the program
runpgz modojr.pgz

