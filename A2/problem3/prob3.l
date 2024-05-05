%option caseless
%option yylineno

%{
    #include "prob3.tab.h"
    #include <stdio.h>
    #include <string.h>
%}

WS                  [ \t\n\r]+
NUMBER              [0-9]+
VALUE               \"({WS})?{NUMBER}({WS})?\"|\"{WS}?{NUMBER}|{NUMBER}{WS}?\"|{NUMBER}
OPENING_BRACKET     "<"
CLOSING_BRACKET     ">"
QUIZ                "quiz"
SINGLE_SELECT       "singleselect"
MULTI_SELECT        "multiselect"
CHOICE              "choice"
MARKS               "marks"
EQUAL               "="
CORRECT             "correct"
TEXT                >[^<]*

OPENING_QUIZ_TAG    {OPENING_BRACKET}({WS})?{QUIZ}({WS})?
CLOSING_QUIZ_TAG    {OPENING_BRACKET}({WS})?"/"({WS})?{QUIZ}({WS})?{CLOSING_BRACKET}
OPENING_SINGLE_TAG  {OPENING_BRACKET}({WS})?{SINGLE_SELECT}({WS})?
CLOSING_SINGLE_TAG  {OPENING_BRACKET}({WS})?"/"({WS})?{SINGLE_SELECT}({WS})?{CLOSING_BRACKET}
OPENING_MULTI_TAG   {OPENING_BRACKET}({WS})?{MULTI_SELECT}({WS})?
CLOSING_MULTI_TAG   {OPENING_BRACKET}({WS})?"/"({WS})?{MULTI_SELECT}({WS})?{CLOSING_BRACKET}
OPENING_CHOICE_TAG  {OPENING_BRACKET}({WS})?{CHOICE}({WS})?
CLOSING_CHOICE_TAG  {OPENING_BRACKET}({WS})?"/"({WS})?{CHOICE}({WS})?{CLOSING_BRACKET}
OPENING_CORRECT_TAG {OPENING_BRACKET}({WS})?{CORRECT}({WS})?
CLOSING_CORRECT_TAG {OPENING_BRACKET}({WS})?"/"({WS})?{CORRECT}({WS})?{CLOSING_BRACKET}

%%

{OPENING_QUIZ_TAG}      {return T_QOpen;}
{CLOSING_QUIZ_TAG}      {return T_QClose;}
{OPENING_SINGLE_TAG}    {return T_SOpen;}
{CLOSING_SINGLE_TAG}    {return T_SClose;}
{OPENING_MULTI_TAG}     {return T_MOpen;}
{CLOSING_MULTI_TAG}     {return T_MClose;}
{OPENING_CHOICE_TAG}    {return T_ChoiceOpen;}
{CLOSING_CHOICE_TAG}    {return T_ChoiceClose;} 
{OPENING_CORRECT_TAG}   {return T_CorrectOpen;}
{CLOSING_CORRECT_TAG}   {return T_CorrectClose;}
{MARKS}                 {return T_Marks;}
{EQUAL}                 {return T_Assign;}
{VALUE}                 {yylval.stringValue = yytext; return T_Value;}
{TEXT}                  {;}
{WS}                    {;}
.                       {;}


%%

// int main() {
//     yylex();

//     return 0;
// }