# SIMPLE BASH SCRIPT TO ASSEMBLE, LINK AND FIX GAMEBOY SOURCES WITH RGBDS
# =======================================================================
# * Searches for source files in a ./src directory with specified extension
# * Generates .obj .sym and .map files in a ./obj directory
# * Generates .gb file with specified name in a ./game directory

game_name=Wyhrm
src_extension=asm

# Error management
# ----------------
function errorA {
echo "║ ERROR! Failed Assembly."
echo "║    │"
echo "╚════╩═══════════════════╗"
echo "   ENDED WITH ERRORS     ╝"
exit
}

function errorL {
echo "║ ERROR! Failed Link."
echo "║    │"
echo "╚════╩═══════════════════╗"
echo "   ENDED WITH ERRORS     ╝"
exit
}

function errorF {
echo "║ ERROR! Failed Fix."
echo "║    │"
echo "╚════╩═══════════════════╗"
echo "   ENDED WITH ERRORS     ╝"
exit
}

# Scrpit
# ------
echo "   START                 ╗"
echo "╔═╦══════════════════════╝"
echo "║ ├ Assembly started ..."
echo "║ │"
echo "║ └──┬ Assembling ..."

shopt -s nullglob
for i in ./src/*.${src_extension}; do
  j=${i:6}
  rgbasm -o ./obj/${j%.*}.obj $i || errorA
done # Iterates throug all the soruce files in ./src/ directory

echo "║    ├── 🗸"
echo "║    │"
echo "║    ├ Linking ..."

rgblink -o ./game/${game_name}.gb -m ./game/${game_name}.map -n ./game/${game_name}.sym ./obj/*.obj || errorL

echo "║    ├── 🗸"
echo "║    │"
echo "║    ├ Fixing ..."

rgbfix -v -p0 ./game/${game_name}.gb || errorF

echo "║    ├── 🗸"
echo "║    │"
echo "╚════╩═══════════════════╗"
echo "   ENDED CORRECTLY       ╝"


#if [ -f $1.gb ]
#  then
#   rm $1.gb
#fi
