%option yylineno
%option caseless

%{
    #include <iostream>
    #include <string>
    #include <unordered_map>
    #include <set>
    #include <cctype>
    using namespace std;

    set<string>                     lexemes;        // * Store and lexemes, sorted by lexeme
    unordered_map<string, string>   lexeme_token;   // * Store the token of lexemes
    unordered_map<string, int>      lexeme_count;   // * Store the count of lexemes

    string toUpperCase(const string &str) {
        string upperStr;
        for(char c : str) {
            upperStr += toupper(static_cast<unsigned char>(c));
        }
        return upperStr;
    }

    void addLexeme(const string& lexeme, const string& tokenType) {
        // cout << "scanned token is " << lexeme << endl;
        if(tokenType == "CHAR_LITERAL") {
            if(!lexemes.insert(lexeme).second) {
                lexeme_count[lexeme]++;
            }
            else {
                lexeme_count[lexeme] = 1;
                lexeme_token[lexeme] = tokenType;
            }
        }
        else {
            string upperLexeme = toUpperCase(lexeme);
            if(!lexemes.insert(lexeme).second) {
                lexeme_count[upperLexeme]++; // lexeme already read before, only increment count
            } else {
                lexeme_token[lexeme] = tokenType;
                if(lexeme_count.find(upperLexeme) != lexeme_count.end()) {
                    // same word, different case, only increment count
                    lexeme_count[upperLexeme]++;
                }
                else {
                    // New lexeme, set initial count and token type
                    lexeme_count[upperLexeme] = 1;
                }
            }
        }
    }

    void printErrorMessage(const string&lexeme, const int lineNum, const int errorCode) {
        switch(errorCode) {
            case 0:
                cout << "line no. " << lineNum << ", ill-formed string " << lexeme << endl;
                break;
            case 1:
                cout << "line no. " << lineNum << ", identifier " << lexeme << " must begin with an alphabet" << endl;
                break;
            case 2:
                cout << "line no. " << lineNum << ", name " << lexeme << " exceeds maximum allowed length (63)" << endl;
                break;
            case 3:
                cout << "line no." << lineNum << ", exponent can only be integral in the token " << lexeme << endl;
                break;
            case 4:
                cout << "line no. " << lineNum << ", unidentified character " << lexeme << endl;\
                break;
        }
    }
%}

LETTER              [a-z]
DIGIT               [0-9]
DIGIT_STRING        {DIGIT}+
SIGN                [+-]
SIGNED_DIGIT_STRING {SIGN}?{DIGIT_STRING}
CHARACTER_SET       [0-9a-z_]

KIND_PARAM          {DIGIT_STRING}|{NAMES}
SIGNIFICAND         {DIGIT_STRING}"."({DIGIT_STRING}?)|"."{DIGIT_STRING}
EXPONENT_LETTER     [ED]
EXPONENT            {SIGNED_DIGIT_STRING}


KEYWORDS1           allocatable|allocate|assign|associate|asynchronous|backspace|bind|call|case|class|close|common|contains|continue|cycle|codimension|contiguous|critical
KEYWORDS2           data|deallocate|deferred|dimension|do|else|elsewhere|end|endfile|endif|entry|equivalence|exit|external|enum|enumerator|extends
KEYWORDS3           forall|final|flush|format|function|goto|generic|import|if|implicit|inquire|intrinsic|include|interface|intent|lock|module|nopass|namelist|nullify
KEYWORDS4           open|only|operator|optional|parameter|pause|print|program|pointer|private|pass|protected|procedure|public|read|return|recursive|result|rewind|rewrite
KEYWORDS5           save|stop|subroutine|select|sequence|submodule|target|then|use|value|unlock|volatile|while|write
KEYWORDS            {KEYWORDS1}|{KEYWORDS2}|{KEYWORDS3}|{KEYWORDS4}|{KEYWORDS5}


NAMES               {LETTER}{CHARACTER_SET}{0,62}


INT_LITERAL         {SIGN}?{DIGIT_STRING}(_{KIND_PARAM})?
REAL_LITERAL        {SIGN}?{SIGNIFICAND}({EXPONENT_LETTER}{EXPONENT})?(_{KIND_PARAM})?|{SIGN}?{DIGIT_STRING}{EXPONENT_LETTER}{EXPONENT}(_{KIND_PARAM})?
LOGICAL_LITERAL     \.(TRUE|FALSE)\.(_{KIND_PARAM})?
CHAR_LITERAL        (\"[^\'^\"]*\")
LITERALS            {INT_LITERAL}|{REAL_LITERAL}|{LOGICAL_LITERAL}|{CHAR_LITERAL}


REL_OP              ".EQ."|".NE."|".LT."|".LE."|".GT."|".GE."|"=="|"/="|"<"|"<="|">"|">="
INTRINSIC_OPERATOR  "**"|"*"|"/"|"+"|"-"|"//"|".NOT."|".AND."|".OR."|".EQV."|".NEQV."|{REL_OP}
OPERATORS           {INTRINSIC_OPERATOR}|"="|"%"|"&"|"&&"|"<<"|">>"|"||"


DELIMITERS          "("|")"|"["|"]"|"(/"|"/)"
COMMENTS            ^![^\n]*(\n)?
    /* newline is optional since the comment can be the last line of a program */
SPECIAL_CHAR        \\|"{"|"}"|","|"."|":"|";"|"!"|\"|"~"|"?"|\'|"`"|"^"|"|"|"$"|"#"|"@"

WHITE_SPACE         [ \n\t\r\f]+
INV_STRING          \"([^\'^\"]*['][^\'^\"]*)+\"|\"[^\"]*
INV_IDENTIFIER      ({DIGIT}|[_])+{NAMES}
LONG_NAMES          {NAMES}{CHARACTER_SET}+
INV_REAL_LITERAL    {SIGN}?{SIGNIFICAND}({EXPONENT_LETTER}{SIGNIFICAND})?(_{KIND_PARAM})?|{SIGN}?{DIGIT_STRING}{EXPONENT_LETTER}{SIGNIFICAND}(_{KIND_PARAM})?

%%
    // ignore comments and white spaces
{WHITE_SPACE}               {;}
{COMMENTS}                  {;}
{INV_STRING}                {printErrorMessage(yytext, yylineno, 0);}
{INV_IDENTIFIER}            {printErrorMessage(yytext, yylineno, 1);}
{KEYWORDS}                  {addLexeme(yytext, "KEYWORD");}
{NAMES}                     {addLexeme(yytext, "NAME");}
{LONG_NAMES}                {printErrorMessage(yytext, yylineno, 2);}
{INT_LITERAL}               {addLexeme(yytext, "INT_LITERAL");}
{REAL_LITERAL}              {addLexeme(yytext, "REAL_LITERAL");}
{INV_REAL_LITERAL}          {printErrorMessage(yytext, yylineno, 3);}
{LOGICAL_LITERAL}           {addLexeme(yytext, "LOGICAL_LITERAL");}
{CHAR_LITERAL}              {addLexeme(yytext, "CHAR_LITERAL");}
{OPERATORS}                 {addLexeme(yytext, "OPERATOR");}
{DELIMITERS}                {addLexeme(yytext, "DELIMITER");}
{SPECIAL_CHAR}              {addLexeme(yytext, "SPECIAL_CHAR");}
.                           {printErrorMessage(yytext, yylineno, 4);}
%%

int main() {
    yylex();
    int count;
    string tokenType;
    cout << "TOKEN\t\tCOUNT\t\tLEXEME" << endl;
    cout << "----------------------------------------" << endl;
    for (const auto& lexeme : lexemes) {
        tokenType = lexeme_token[lexeme];
        if(tokenType != "CHAR_LITERAL") {
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