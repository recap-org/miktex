#!/bin/bash

miktexsetup finish --shared=yes
miktex --admin packages update-package-database
miktex --admin packages update
miktex packages update-package-database
miktex packages update
mpm --admin --verbose --package-level=basic --upgrade