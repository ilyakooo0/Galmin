# Galmin

Galmin is a command line application for generating the full solution to the problem of the traveling salesman between six give fully connected points.

## Input

On launch you will be asked to enter the coordinates of six points for which the application should generate the solution. 

The weight of the edge between two given points is then calculated using the following formula: `|AB| =  |Xa - Xb| + |Ya - Yb|`.

## Output 

Out files are created in the directory `diskraDz3`. Output consists of six `.csv` files and one `.gv` file for every step of the solution and one `solution.txt` containing the actual solution to the problem. 

The `.gv` file is is a [GraphViz](http://www.graphviz.org/) file. Displays correctly only when exporting as `.svg`. 

## Support

Swift 4. 

Is intended to work as a mac command line application. Linux support is rudimentary. Doesn't work with embedded standard library (requires Swift standard library to be installed).
