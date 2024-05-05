%option yylineno
%option caseless

%{
    #include <iostream>
    #include <string>
    #include <set>
    #include <unordered_map>
    #include <cctype>
    using namespace std;

    string toUpperCase(const string &str) {
        string upperStr;
        for(char c : str) {
            upperStr += toupper(static_cast<unsigned char>(c));
        }
        return upperStr;
    }

    set<string>                     lexemes;        // * Store and lexemes, sorted by lexeme
    unordered_map<string, string>   lexeme_token;   // * Store the token of lexemes
    unordered_map<string, int>      lexeme_count;   // * Store the count of lexemes

    void addLexeme(const string& lexeme, const string& tokenType) {
        string upperLexeme = toUpperCase(lexeme);
        if(!lexemes.insert(lexeme).second) {
            if(tokenType == "KEYWORD" || tokenType == "OPERATOR") {
                lexeme_count[upperLexeme]++; // lexeme already read before, only increment count
            }
            else {
                lexeme_count[lexeme]++;
            }
        } else {
            // New lexeme, set initial count and token type
            if((tokenType == "KEYWORD" || tokenType == "OPERATOR")
                && lexeme_count.find(upperLexeme) != lexeme_count.end()) {
                    // the case-insensitive string already existed, this occurance was in a different case
                    lexeme_count[upperLexeme]++;
                    lexeme_token[lexeme] = tokenType;
            }
            else {
                // either first occurance of a keyword/op or a different token type (case sensitive)
                if(tokenType == "KEYWORD" || tokenType == "OPERATOR") {
                    lexeme_count[upperLexeme] = 1;
                }
                else {
                    lexeme_count[lexeme] = 1;
                }
                lexeme_token[lexeme] = tokenType; // need it associated with each token since it is used to backtrack count when printing
            }
        }
    }
    void printErrorMessage(const string& lexeme, const int lineNum, const int errorCode) {
        switch (errorCode) {
            case 0:
                cout << "line no. " << lineNum << ", invalid float " << lexeme << endl;
                break;
            case 1:
                cout << "line no. " << lineNum << ", floating point with more than 6 decimal digits " << lexeme << endl;
                break;
            case 2:
                cout << "line no. " << lineNum << ", hexadecimal float not allowed " << lexeme << endl;
                break;
            case 3:
                cout << "line no. " << lineNum << ", leading zeros not allowed " << lexeme << endl;
                break;
            case 4:
                cout << "line no. " << lineNum << ", identifier cannot begin with a digit " << lexeme << endl;
                break;
            case 5:
                cout << "line no. " << lineNum << ", illformed string " << lexeme << endl;
                break;
            case 6:
                cout << "line no. " << lineNum << ", unidentified token " << lexeme << endl;
                break;
        }
    }
%}

LETTER          [a-zA-Z]
DIGIT           [0-9]
ZERO            "0"
WHOLE_DIGIT     [1-9]
HEX_DIGIT       [0-9a-f]

KEYWORDS        ARRAY|BEGIN|BOOLEAN|COMMENT|CONTINUE|DO|DOUBLE|ELSE|END|FALSE|FOR|IF|INTEGER|LABEL|LIST|LONG|OWN|PROCEDURE|STEP|SWITCH|THEN|TRUE|UNTIL|VALUE|WHILE
OPERATORS       AND|OR|LEQ|LT|GEQ|GT|NOT|EQL|NEQ|":="|"+"|"-"|"*"|"/"|"%"|"^"|"|"|"&"|"<<"|">>"
IDENTIFIER      (?-i:{LETTER}({LETTER}|{DIGIT})*)
STRING          (\"[^\'^\"]*\")|(\'[^\'^\"]*\')
DELIMITER       ";"|":"|","|\'|\"|"["|"]"|"{"|"}"|"("|")"
INTEGER         {ZERO}|({WHOLE_DIGIT}{DIGIT}*)
FLOATING_POINT  ({ZERO}"."{DIGIT}{1,6})|({WHOLE_DIGIT}{DIGIT}*"."{DIGIT}{1,6})
HEXADECIMAL     "0x0"|(0x[1-9a-f][0-9a-f]*)
COMMENTS        \{[^\}]*\}
WHITE_SPACE     [ \t\f\n]+
LEADING_ZEROS   ([0]{DIGIT}+)|([0]{HEX_DIGIT}+[x]{HEX_DIGIT}*)|([0][x][0]{HEX_DIGIT}+)|([0]{DIGIT}+"."{DIGIT}*)
INV_FLOAT       ("."{DIGIT}+)
FLOAT_CAPACITY  ({ZERO}"."{DIGIT}{7,})|({WHOLE_DIGIT}{DIGIT}*"."{DIGIT}{7,})
HEX_FLOAT       [0][x]{HEX_DIGIT}*"."{HEX_DIGIT}*
    /*This includes various cases when numbers are followed without space with another character and also floating point numbers with >6 decimal digits*/
INV_IDENTIFIER  {DIGIT}+{IDENTIFIER}
    /*This definition of INV_IDENTIFIER includes cases when we have numbers followed by digits, eg. 123abc or even invalid hexadecimal cases, 0x12adsa, since it won't match with hex*/
INV_STRING      \"([^\'^\"]*['][^\'^\"]*)+\"|\'([^\'^\"]*["][^\'^\"]*)+\'|\"[^\"]*|\'[^\']*

%%

{WHITE_SPACE}|{COMMENTS}    {;} //ignore white spaces and comments
{INV_FLOAT}                 {printErrorMessage(yytext, yylineno, 0);}
{FLOAT_CAPACITY}            {printErrorMessage(yytext, yylineno, 1);}
{HEX_FLOAT}                 {printErrorMessage(yytext, yylineno, 2);}
{LEADING_ZEROS}             {printErrorMessage(yytext, yylineno, 3);}
{HEXADECIMAL}               {addLexeme(yytext, "HEXADECIMAL");}
    /* hexadecimal has to be detected before INV_IDENTIFIER otherwise it is detected as DIGIT followed by ID */
{INV_IDENTIFIER}            {printErrorMessage(yytext, yylineno, 4);}
{INV_STRING}                {printErrorMessage(yytext, yylineno, 5);}
{KEYWORDS}                  {addLexeme(yytext, "KEYWORD");}
{OPERATORS}                 {addLexeme(yytext, "OPERATOR");}
{IDENTIFIER}                {addLexeme(yytext, "IDENTIFIER");}
{STRING}                    {addLexeme(yytext, "STRING");}
{DELIMITER}                 {addLexeme(yytext, "DELIMITER");}
{INTEGER}                   {addLexeme(yytext, "INTEGER");}
{FLOATING_POINT}            {addLexeme(yytext, "FLOATING_POINT");}
.                           {printErrorMessage(yytext, yylineno, 6);}
%%

int main() {
    yylex();
    
    int count;
    string tokenType;
    cout << "TOKEN\t\tCOUNT\t\tLEXEME" << endl;
    cout << "----------------------------------------" << endl;
    for (const auto& lexeme : lexemes) {
        tokenType = lexeme_token[lexeme];
        if(tokenType == "KEYWORD" || tokenType == "OPERATOR") {
            count = lexeme_count[toUpperCase(lexeme)];
        }
        else {
            count = lexeme_count[lexeme];
        }
        if(tokenType.length() > 7) {
            cout    << tokenType << "\t"  
                    << count << "\t\t" 
                    << lexeme << endl;
        }
        else {
            cout    << tokenType << "\t\t"  
                    << count << "\t\t" 
                    << lexeme << endl;
        }
    }

    return 0;
}