#!/bin/bash
set -e

cd test
find . -maxdepth 1 -type f ! -name '*.tex' ! -name '*.bib' -delete
latexmk  -pdf text-latex.tex
latexmk  -pdflua text-luatex.tex
latexmk  -pdfxe text-xetex.tex