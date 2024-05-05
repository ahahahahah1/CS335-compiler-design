%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    
    int num_ques = 0, num_sing_ques = 0, num_mult_ques = 0;
    int total_num_choices = 0, total_num_correct = 0;
    int num_choices = 0, num_correct = 0;
    int given_marks = 0;
    int total_marks = 0;
    int num_mark_ques[8] = {0};

    int err_line_num = 0;
    extern int yylineno;

    int print_stats() {
        printf("Number of questions: %d\n", num_ques);
        printf("Number of singleselect questions: %d\n", num_sing_ques);
        printf("Number of multiselect questions: %d\n", num_mult_ques);
        printf("Number of answer choices: %d\n", total_num_choices);
        printf("Number of correct answers: %d\n", total_num_correct);
        printf("Total marks: %d\n", total_marks);

        for(int i = 0; i < 8; i++) {
            printf("Number of %d marks questions: %d\n", i+1, num_mark_ques[i]);
        }
        return 0;
    }

    void yyerror(const char *s) {
        print_stats();
        printf("\n");
        printf("Line number %d: %s\n", err_line_num, s);
        exit(1);
    }
    extern int yylex(void);

    int extractNumber(char *s) {
        int k = 0;
        size_t length = strlen(s);
        if(s[0] != '\"' || s[length - 1] != '\"') {
            yyerror("Marks attribute must be enclosed within \"");
        }
        for(int i = 0; i < length; i++) {
            if(s[i] >= '0' && s[i] <= '9') {
                k = k * 10 + (s[i] - '0');
            }
        }
        return k;
    }

    int validate(int marks, int Q_type) {
        total_marks += marks;
        num_ques++;
        if(Q_type == 0) {
            num_sing_ques++;
            // single-select type question
            if(marks != 1 && marks != 2) {
                yyerror("Marks for a single select type question must be either 1 or 2");
            }
        }
        else {
            num_mult_ques++;
            if(marks < 2 || marks > 8) {
                yyerror("Marks for a multi select type question must be between 2 and 8");
            }
        }
        num_mark_ques[given_marks - 1]++;
        return 0; // gcc shutup!
    }

    int verify_and_update(int Q_type) {
        if(Q_type == 0) {
            // single-select question type
            if(num_correct != 1) {
                yyerror("Number of correct choices must be 1 for a single select type question");
            }
        }
        else {
            // multi-select question type
            if(num_correct > num_choices) {
                yyerror("Number of correct choices cannot be greater than the number of choices");
            }
        }
        if(num_choices != 3 && num_choices != 4) {
            yyerror("Number of choices for a question must be 3 or 4");
        }
        if(num_correct == 0) {
            yyerror("There must be at least 1 correct choice for each question");
        }
        num_choices = num_correct = 0; // resetting the values for the next question
    }

%}

%union {
    int intValue;
    char *stringValue;
}

%token T_QOpen T_QClose
%token T_SOpen T_SClose
%token T_MOpen T_MClose
%token T_Marks T_Assign T_Value
%token T_ChoiceOpen T_ChoiceClose
%token T_CorrectOpen T_CorrectClose


%%

prog                :   T_QOpen question_sequence T_QClose optional_number
                    |                   // this is not an error case, an empty program is also a valid program
                    |   error_prog     // will generate sequences of erroneous cases
                    ;
question_sequence   :   question question_sequence
                    |   error_question // this will generate the erroneous cases
                    |
                    ;

question            :   single 
                    |   multi
                    ;
error_question      :   error_single
                    |   error_multi
                    ;

single              :   single_start options T_SClose {verify_and_update(0);} optional_number
                    ;
single_start        :   T_SOpen {err_line_num = yylineno;} T_Marks T_Assign T_Value {given_marks = extractNumber(yylval.stringValue); validate(given_marks, 0);}
                    ;
multi               :   multi_start options T_MClose {verify_and_update(1);} optional_number
                    ;
multi_start         :   T_MOpen {err_line_num = yylineno;} T_Marks T_Assign T_Value {given_marks = extractNumber(yylval.stringValue); validate(given_marks, 1);}
                    ;

options             :   correct {total_num_correct++; num_correct++;} options
                    |   choice {total_num_choices++; num_choices++;} options
                    |   T_ChoiceClose { err_line_num = yylineno; yyerror("missing opening choice tag");}
                    |   T_CorrectClose { err_line_num = yylineno; yyerror("missing opening correct tag");}   
                    |   T_ChoiceOpen errorChoice_tokens {err_line_num = yylineno; yyerror("missing closing choice tag");}
                    |   T_CorrectOpen errorCorrect_tokens {err_line_num = yylineno; yyerror("missing closing correct tag");}
                    |
                    ;
                    
choice              :   T_ChoiceOpen T_ChoiceClose optional_number
                    ;
correct             :   T_CorrectOpen T_CorrectClose optional_number
                    ;

error_prog          :   no_QOpen {err_line_num = yylineno; yyerror("missing opening quiz tag");}
                    |   T_QOpen question_sequence {err_line_num = yylineno; yyerror("missing closing quiz tag");}
                    ;

no_QOpen            :   T_QClose
                    |   T_SOpen | T_SClose
                    |   T_MOpen | T_MClose
                    |   T_Marks | T_Assign | T_Value
                    |   T_ChoiceOpen | T_ChoiceClose
                    |   T_CorrectOpen | T_CorrectClose
                    ;

error_question      :   error_single
                    |   error_multi
                    ;

error_single        :   options T_SClose {err_line_num = yylineno; yyerror("missing opening singleselect tag");}
                    |   single_start options errorSingle_tokens {yyerror("missing closing singleselect tag");}
                    ;

errorSingle_tokens  :   T_QClose
                    |   T_MOpen | T_MClose | T_SOpen
                    ;

error_multi         :   options T_MClose {err_line_num = yylineno; yyerror("missing opening multiselect tag");}
                    |   multi_start options errorMulti_tokens {yyerror("missing closing multiselect tag");}
                    ;

errorMulti_tokens   :   T_QClose
                    |   T_SOpen | T_SClose | T_MOpen
                    |   T_Marks | T_Assign | T_Value
                    ;

errorChoice_tokens  :   T_SClose | T_MClose | T_CorrectOpen | T_CorrectClose | T_ChoiceOpen
                    |   T_Marks | T_Assign | T_Value
                    ;

errorCorrect_tokens :   T_SClose | T_MClose | T_ChoiceOpen | T_ChoiceClose | T_CorrectOpen
                    |   T_Marks | T_Assign | T_Value
                    ;

optional_number     :   T_Value optional_number
                    |
                    ;
%%

int main() {
    yyparse();
    print_stats();
    return 0;
}
