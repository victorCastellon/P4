#!/bin/bash

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## 
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.

# Base name for temporary files
base=/tmp/$(basename $0).$$

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() { #es el programa que se ejecuta cando leemos EXIT
   \rm -f $base.*
}

#Se comprueba si el número de argumentos pasados al programa es != 0
if [[ $# != 3 ]]; then
   echo "$0 lpc_order input.wav output.lp"
   exit 1
fi

#Almacenamiento de los parámetros.
lpc_order=$1
inputfile=$2
outputfile=$3

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then #Cambiamos los parámetros dependiendo de qué SO tenemos.
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   LPC="sptk lpc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   LPC="lpc"
fi

# Main command for feature extration --> 
# Pipeline principal
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpc_order > $base.lp

# Our array files need a header with the number of cols and rows:
ncol=$((lpc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.lp | wc -l | perl -ne 'print $_/'$ncol', "\n";'`
# fa: formato de entrada float, formada de salida ascii. Esto lo saca del fichero lp.
# wc: word count

# nrow=`$X2X +fa < $base.lp | wc -l | perl -ne 'print $_/'$ncol', "\n";'`
#calcula el nº de filas y de columnas y lo introduce en un fichero nuevo

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
# formato de entrada ascii, formato de salida I (integer de 4 bytes).
cat $base.lp >> $outputfile

exit
