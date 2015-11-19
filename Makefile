CC=cc
AR=ar rcu
RANLIB=ranlib
#USESSL=openssl
USESSL=mbed

#CFLAGS=-Wall -Wpointer-arith -O2 -g -fsanitize=address -mtune=core2
CFLAGS=-Wall -Wpointer-arith -O2 -g -fno-stack-protector -fomit-frame-pointer -mtune=core2
#CFLAGS=-O2 -g -pg

LIB_A=psynclib.a

ifeq ($(OS),Windows_NT)
    CFLAGS += -DP_OS_WINDOWS
    LIB_A=psynclib.dll
    AR=$(CC) -shared -o
    RANLIB=strip --strip-unneeded
    LDFLAGS=-s
else
    UNAME_S := $(shell uname -s)
    UNAME_V := $(shell uname -v)
    ifeq ($(UNAME_S),Linux)
        CFLAGS += -DP_OS_LINUX
            ifneq (,$(findstring Debian,$(UNAME_V)))
                CFLAGS += -DP_OS_DEBIAN
            endif
	LDFLAGS += -lssl -lcrypto -lfuse -lpthread -lsqlite3
    endif
    ifeq ($(UNAME_S),Darwin)
        CFLAGS += -DP_OS_MACOSX -I/usr/local/ssl/include/
        CFLAGS += -DP_OS_MACOSX -I/usr/local/include/osxfuse/
	LDFLAGS += -lssl -lcrypto -losxfuse -lsqlite3 -framework Cocoa -L/usr/local/ssl/lib
        #USESSL=securetransport
    endif
endif

OBJ=pcompat.o psynclib.o plocks.o plibs.o pcallbacks.o pdiff.o pstatus.o papi.o ptimer.o pupload.o pdownload.o pfolder.o\
     psyncer.o ptasks.o psettings.o pnetlibs.o pcache.o pscanner.o plist.o plocalscan.o plocalnotify.o pp2p.o\
     pcrypto.o pssl.o pfileops.o ptree.o ppassword.o prunratelimit.o pmemlock.o pnotifications.o pexternalstatus.o publiclinks.o\
     pbusinessaccount.o pcontacts.o poverlay.o poverlay_lin.o poverlay_win.o overlay_client.o

OBJFS=pfs.o ppagecache.o pfsfolder.o pfstasks.o pfsupload.o pintervaltree.o pfsxattr.o pcloudcrypto.o pfscrypto.o pcrc32c.o pfsstatic.o plocks.o

OBJNOFS=pfsfake.o

ifeq ($(USESSL),openssl)
  OBJ += pssl-openssl.o
  CFLAGS += -DP_SSL_OPENSSL
endif
ifeq ($(USESSL),securetransport)
  OBJ += pssl-securetransport.o
  CFLAGS += -DP_SSL_SECURETRANSPORT
endif
ifeq ($(USESSL),mbed)
  OBJ += pssl-mbedtls.o
  CFLAGS += -DP_SSL_MBEDTLS -I../../mbedtls-1.3.10/include/
endif

OBJ1=overlay_client.o

all: $(LIB_A)

$(LIB_A): $(OBJ) $(OBJNOFS)
	$(AR) $@ $(OBJ) $(OBJNOFS)
	$(RANLIB) $@

fs: $(OBJ) $(OBJFS)
	$(AR) $(LIB_A) $(OBJ) $(OBJFS)
	$(RANLIB) $(LIB_A)

cli: fs
	$(CC) $(CFLAGS) -o cli cli.c $(LIB_A) $(LDFLAGS)
	
overlay_client: $(OBJ1)
	$(CC) $(CFLAGS) $(OBJ1) -o overlay_client

clean:
	rm -f *~ *.o $(LIB_A)

