
CLANG_BIN=`xcrun --sdk macosx --find clang`

CLANG_UNIVERSAL=$(CLANG_BASE) -arch x86_64 -arch i386

SDK=`xcrun --sdk macosx --show-sdk-path`

CFLAGS=-Wno-non-literal-null-conversion -Wno-unused-command-line-argument -fobjc-arc

CLANG_BASE = $(CLANG_BIN) -Os $(CFLAGS) -isysroot $(SDK) -F$(SDK)/System/Library/Frameworks


vpath %.m ../insert_remove_dylib:../insert_remove_dylib/Insert_dylib:../insert_remove_dylib/Remove_dylib
vpath %.h ../insert_remove_dylib/Insert_dylib:../insert_remove_dylib/Remove_dylib

all: Insert_Remove_dylib

Insert_Remove_dylib: Insert_dylib.o main.o Remove_dylib.o
	$(CLANG_UNIVERSAL) -framework Foundation -o $@ $^

Insert_dylib.o: Insert_dylib.m
	$(CLANG_UNIVERSAL) -x objective-c -framework Foundation -c -o $@ $^

Remove_dylib.o: Remove_dylib.m
	$(CLANG_UNIVERSAL) -x objective-c -framework Foundation -c -o $@ $^

main.o: main.m
	$(CLANG_UNIVERSAL) -x objective-c -framework Foundation -c -o $@ $^
clean:
	rm -f *.o Insert_Remove_dylib