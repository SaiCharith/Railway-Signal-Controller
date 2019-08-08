#! /bin/bash
CDIR=$(pwd)
for i in $(ls -R | grep :); do
    DIR=${i%:}                    # Strip ':'
    cd $DIR
    if [ -e "Makefile" ]; then
    	make
	fi
    cd $CDIR
done
