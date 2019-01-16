#! /bin/bash
# --------------
# PRE-PROCESSING
# --------------
# Incorporate the parameters from DAKOTA into the template

# getting workdir tag
name=${PWD##*/}

export num=`echo $name | cut -c 9-`

# copy any necessary files and data files into workdir
cd ../
cp mosdak.template workdir.$num/
#cp mesh_file.e workdir.$num/
cp dprepro workdir.$num/
cp mosdak.i workdir.$num/

# RUN the simulation from workdir.num
cd workdir.$num/
#input params.in into the moose simulation
./dprepro --left-delimiter=% --right-delimiter=% params.in mosdak.template mosdak.i

# --------
# ANALYSIS
# --------
#
mpirun -np 8 ../../picachu-opt -i mosdak.i > temp.out

# ---------------
# POST-PROCESSING
# ---------------
# extract function value from the simulation output - Attention with the order!!
# 1 line for each response function
#for testing
#tail -n+2 moose_out.csv|cut -f3 -d','

tail -1 mosdak_out.csv|cut -f1 -d',' >> results.tmp
tail -1 mosdak_out.csv|cut -f2 -d',' >> results.tmp

# write results.out and cleanup
cp results.tmp ./results.out
cd ../
