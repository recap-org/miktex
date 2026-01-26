#!/bin/bash

cd test
pdflatex sample2e
luatex text-luatex.tex
xetex text-xetex.tex