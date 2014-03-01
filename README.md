OpenCLPRNGs
===========

A simple comparision of OpenCL PRNGs.
I've done this as a part of research for my final project. It contains tests for speed and the ability to work with a different number of randoms in work-items, using simple DTMC - [Knuth and Yao die algorithm](http://www.prismmodelchecker.org/tutorial/die.php).

Tested PRNGs:
* [mwc64x](http://cas.ee.ic.ac.uk/people/dt10/research/rngs-gpu-mwc64x.html)
* [OpenCL PRNG Library](http://theorie.physik.uni-wuerzburg.de/~hinrichsen/software/random/OpenCL_PRNG/doc/index.html)
* [Random123](http://www.thesalmons.org/john/random123/releases/1.06/docs/)

## Compiling

Everything is one file `main.c`. You can use `Makefile`, just type:

```
make
```

Specifying OpenCL location in `Makefile` may not be necessary.

## Usage

Syntax for summing random vars:

```
[number of work-items] [number of randoms in each work-item] [prng name]
```

Syntax for simple DTMC check:

```
[number of work-items] [prng name]-random
```
