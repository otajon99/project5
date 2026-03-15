#!/bin/bash

# Author: Otajon
# Created: 08/19/2025
# Content: Counting 1 to 5 and opposite
# Optimized for better performance

# Forward counting - optimized loop without sleep delay
echo "Counting forward:"
for ((i=1; i<=5; i++)); do
    echo "Forward: $i"
done

# Backward counting - optimized C-style loop
echo
echo "Counting backward:"
for ((a=5; a>=1; a--)); do
    echo "Backward: $a"
done


