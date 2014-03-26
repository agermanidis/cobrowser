#!/bin/bash

echo "<html><body><script src='$1.js'></script></body></html>" > pages/$1.html
cat > pages/$1.js
