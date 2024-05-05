#!/bin/bash
clear
file_name="../assign1/problem1/testcases/public/public4"

flex prob1.l
g++ lex.yy.c -ll

if [[ "$1" == "-f" ]]; then
    (./a.out < "${file_name}.knp") > "${file_name}.output"
else
    ./a.out < "${file_name}.knp"
fi

rm ./a.out
rm ./lex.yy.c