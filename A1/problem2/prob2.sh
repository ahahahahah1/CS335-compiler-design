#!/bin/bash
clear
file_name="../assign1/problem2/testcases/private/private11"

flex prob2.l
g++ lex.yy.c -ll

if [[ "$1" == "-f" ]]; then
    (./a.out < "${file_name}.f08") > "${file_name}.output"
else
    ./a.out < "${file_name}.f08"
fi

rm ./a.out
rm ./lex.yy.c