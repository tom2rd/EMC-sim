#! /bin/bash
echo Convert a CATIA STL mesh Triangle file to a NEC2 Surface Patch file
echo Usage: stl2nec inputfile outputfile
echo Example: stl2nec canopy.stl canopy.nec
#
# Configuration:
# None
#
# solid CATIA STL
#  facet normal  0.000000e+000  2.623846e-002 -9.996557e-001
#    outer loop
#      vertex -7.888865e+002  1.000000e+000 -1.510123e+002
#      vertex -8.452780e+002  1.000000e+000 -1.510123e+002
#      vertex -7.888881e+002  1.104642e+000 -1.510096e+002
#    endloop
#  endfacet
#  ...
#  facet normal  0.000000e+000  0.000000e+000 -9.999999e-001
#    outer loop
#      vertex -8.452780e+002  1.000000e+000 -1.510123e+002
#      vertex -7.888865e+002 -1.000000e+000 -1.510123e+002
#      vertex -8.452780e+002 -1.000000e+000 -1.510123e+002
#    endloop
#  endfacet
# endsolid CATIA STL
#
# The normal vector can be ignored
# Each triangle is defined by three x, y, z vertices
# The STL file is assumed to be in mm and is scaled to m with a GS card
#
# NEC Text File Format:
# The original Fortran NEC used punch cards with strict columnar data
# It is now done with lines in a text file
# A text line can use either spaces or commas as field delimeters
# Empty fields are padded with a zero
# The end of the line need not be padded with zeros
# Floating point numbers need to be in exponential format with decimal points
# Bash doesn't do exponential arithmetic (use bc), but the printf function can output it
# The locale settings in the printf statements below ensure use of decimal points
#
#
# Parameter Error check:
if [ "$#" -ne 2 ]
then
  echo ERROR: Missing filename parameters
  echo Example: stl2nec canopy.stl canopy.nec
  exit 1
fi

# File Names:
if [ -e "$1" ]
then
    echo "Input file $1"
    export mesh="$1"
    export nec="$2"
else
    echo ERROR: No input file found
    echo Example: stl2nec canopy.stl canopy.nec
    exit 1
fi
# The above should catch most fat finger issues

#
# Mesh file parse states:
# solid, facet, outer, vert1, vert2, vert3, endloop, endfacet, endsolid
export state="solid"
export vert1="0"
export vert2="0"
export vert3="0"
export errmax=100000
#
# NEC file data:
export wire="1"
export segments="1"
#
# Create the header of the NEC2 file
echo "CM NEC2 Card Stack Produced by s2n"
echo "CM NEC2 Card Stack Produced by s2n">"$nec"
echo "CE"
echo "CE">>"$nec"
#
# Read lines from the mesh file
end_of_mesh_file=0
while [ $end_of_mesh_file == 0 ]
do
  read -r meshline
  # the last exit status is the
  # flag of the end of file
  end_of_mesh_file=$?
  #
  echo "$meshline"
  data=($(echo $meshline | tr -d '\r' ))
  #
  if [ "${data[0]}" == "endsolid" ];
  then
    state="endsolid"
    #echo "state: $state"
  fi
  #
  if [ "$state" == "solid" ];
  then
    #echo "state: $state"
    if [ "${data[0]}" == "facet" ];
    then
      state="facet"
    fi
  elif  [ "$state" == "facet" ];
  then
    #echo "state: $state"
    if [ "${data[0]}" == "outer" ];
    then
      state="outer"
    fi
  elif [ "$state" == "outer" ];
  then
    #echo "state: $state"
    if [ "${data[0]}" == "vertex" ];
    then
      state="vert1"
      #echo "state: $state"
      #echo "vx1: ${data[1]}"
      vx1="${data[1]}"
      #echo "vy1: ${data[2]}"
      vy1="${data[2]}"
      #echo "vz1: ${data[3]}"
      vz1="${data[3]}"
      state="vert2"
    fi
  elif [ "$state" == "vert2" ];
  then
    #echo "state: $state"
    if [ "${data[0]}" == "vertex" ];
    then
      #echo "vx2: ${data[1]}"
      vx2="${data[1]}"
      #echo "vy2: ${data[2]}"
      vy2="${data[2]}"
      #echo "vz2: ${data[3]}"
      vz2="${data[3]}"
      state="vert3"
    fi
  elif [ "$state" == "vert3" ];
  then
    #echo "state: $state"
    if [ "${data[0]}" == "vertex" ];
    then
      #echo "vx3: ${data[1]}"
      vx3="${data[1]}"
      #echo "vy3: ${data[2]}"
      vy3="${data[2]}"
      #echo "vz3: ${data[3]}"
      vz3="${data[3]}"
      #
      # NEC2 Triangular Surface Patch Card
      LC_NUMERIC="en_US.UTF-8" printf "SP 0 2 %.8E %.8E %.8E %.8E %.8E %.8E \n"\
        $vx1 $vy1 $vz1 $vx2 $vy2 $vz2
      LC_NUMERIC="en_US.UTF-8" printf "SP 0 2 %.8E %.8E %.8E %.8E %.8E %.8E \n" \
        $vx1 $vy1 $vz1 $vx2 $vy2 $vz2 >>"$nec"
      LC_NUMERIC="en_US.UTF-8" printf "SC 0 2 %.8E %.8E %.8E \n" \
        $vx3 $vy3 $vz3
      LC_NUMERIC="en_US.UTF-8" printf "SC 0 2 %.8E %.8E %.8E \n" \
        $vx3 $vy3 $vz3 >>"$nec"
      state="facet"
    fi
  fi
done < "$mesh"
#
# Create footer of NEC2 file
# Scale everything from mm to m
#
echo "GS 0 0 .001"
echo "GS 0 0 .001">>"$nec"
echo "GE"
echo "GE">>"$nec"
echo "FR 0 1 0 0 300"
echo "FR 0 1 0 0 300">>"$nec"
echo "EX 1 1 1 0 0"
echo "EX 1 1 1 0 0">>"$nec"
echo "RP 0 90 90 0 0 0 4 4 0 0 0"
echo "RP 0 90 90 0 0 0 4 4 0 0 0">>"$nec"
echo "EN"
echo "EN">>"$nec"
echo "Finis!"
