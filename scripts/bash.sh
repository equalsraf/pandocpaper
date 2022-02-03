
# Wrapper around pandocpaper - requires $PANDOCPAPER to
# point to the main folder; writes to out/
function pandocpaper {
	INPUT_FILE=$1
	TARGET=$2
	NAME=$(basename $(dirname $INPUT_FILE))
	make -f ${PANDOCPAPER}/Makefile INPUT_FILE=$INPUT_FILE $TARGET
}
