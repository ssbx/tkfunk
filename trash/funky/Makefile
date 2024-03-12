
run: transparentglx.bin transparentxrender.bin
	./transparentxrender.bin
	#./transparentglx.bin

transparentxrender.bin: transparentxrender.c
	cc -o transparentxrender.bin transparentxrender.c -lX11 -lGL -lGLU -lXrender -lm

transparentglx.bin: transparentglx.c
	cc -o transparentglx.bin transparentglx.c -lX11 -lGL -lGLU

clean:
	rm -f *.bin
