#!/bin/bash

mkdir -p output

gnuplot -p -e 'set term qt size 1200,1024; set multiplot layout 3,3' burndown.gnuplot
gnuplot -e 'set term postscript colour size 29.7cm,21.0cm font "Times-Roman,8";
set multiplot layout 3,3;' burndown.gnuplot > output/burndown.ps
gnuplot -e 'set term pdf colour size 29.7cm,21.0cm font "Times-Roman,8";
set multiplot layout 3,3;' burndown.gnuplot > output/burndown.pdf
