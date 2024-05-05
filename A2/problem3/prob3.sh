#!/bin/bash

file_name="./private6.txt"

bison -d prob3.y 2>/dev/null 
flex prob3.l
gcc lex.yy.c prob3.tab.c -ll

if [[ "$1" == "-f" ]]; then 
    (./a.out < "${file_name}") > "${file_name}.output"
else
    (./a.out < "${file_name}")
fi

rm lex.yy.c
rm prob3.tab.c
rm prob3.tab.h
rm a.out