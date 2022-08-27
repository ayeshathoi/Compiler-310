%option yylineno
%x STRINGSTATE

%{

#include<bits/stdc++.h>
#include "SymbolTable.h"

#define YYSTYPE SymbolInfo*     
//#include "y.tab.h"
#include "parser.h"
using namespace std;

int line_count = 1;
int error_count = 0;
string str;
string lexeme;
int start_line;

extern ofstream error;
extern ofstream logout;
extern SymbolTable symTab;
extern YYSTYPE yylval;

void printError(string errorName, string lexeme, bool multiline=false){

	error_count++;
	int line_no = multiline ? start_line : yylineno;
	logout << "Error at line " << line_no << ": " << errorName << " " << lexeme << endl << endl;
	error << "Error at line " << line_no << ": " << errorName << " " << lexeme << endl << endl;
}
void InsertToken(string tokenName, string key)
{
	SymbolInfo *s = new SymbolInfo(key, tokenName);
	yylval = s;
}

string EscapeCharacter(string s)
{
	if(s[1]=='t')
		return "\t";
	else if (s[1] =='n'||s[1] == '0')
		return "\n";
	else if (s[1] =='a')
		return "\a";
	else if (s[1] =='r')
		return "\r";
	else if (s[1] =='f')
		return "\f";
	else if (s[1] =='b')
		return "\b";
	else if (s[1] =='v')
		return "\v";
	else if (s[1] =='\'')
		return "\'";
	else if (s[1] =='\\')
		return "\\";
	else if (s[1] =='\"')
		return "\"";
	else return "x";
}


%}

DIGIT [0-9]
LETTER [A-Za-z]
WHITESPACE [ \t\v\f\r]+
NEWLINE \n|\r\n

KEYWORD if|else|for|do|while|switch|case|default|int|float|double|char|void|break|continue|return
RELOP <|<=|>|>=|==|!=
MULOP [*/\%]
INCOP ("++")
DECOP ("--")
LOGICOP ("&&"|"||")
ADDOP [+-]


CONST_INT {DIGIT}+
DECIMAL {CONST_INT}(\.){CONST_INT}?
CONST_FLOAT [0-9]*([.]{CONST_INT})?([eE][-+]?{CONST_INT})?

IDENTIFIER ({LETTER}|_)({LETTER}|_|{DIGIT})*

NORMAL_CHAR_DIGIT ([ -~]{-}['\\])
SPECIAL_CHAR_DIGIT (['][\\][ntafrbv0\'\\]['])
CONST_CHAR \'[^\\^\n]\'|{SPECIAL_CHAR_DIGIT}
MULTI_CHAR_ERROR '(({NORMAL_CHAR_DIGIT}|{SPECIAL_CHAR_DIGIT})({NORMAL_CHAR_DIGIT}|{SPECIAL_CHAR_DIGIT})+)'
UNFINISHED_CHAR_ERROR ('({NORMAL_CHAR_DIGIT}|{SPECIAL_CHAR_DIGIT})*)|[']\\

SINGLELINE_COMMENT [/][/](([\\][\n])|(.))*
MULTILINE_COMMENT (\/\*)([^\*]|\*[^\/])*(\*\/)
UNFINISHED_COMMENT ([/][*])([^\*]|\*[^\/])*

%%
{WHITESPACE} {}
{NEWLINE} { line_count++; }

"if"	{
			return IF;
		}
		
"else"	{
			return ELSE;
		}

"for"	{
			return FOR;
		}

"while"	{
			return WHILE;
		}

"do"	{
			return DO;
		}


"break"	{
			return BREAK;		
		}

"int"	{
			return INT;
		}

"char"	{
			return CHAR;
		}

"float"	{
			return FLOAT;
		}

"double"	{
				return DOUBLE;
			}

"void"	{
			return VOID;
		}

"return"	{
				return RETURN;
			}

"switch"	{
				return SWITCH;
			}

"case"	{
			return CASE;
		}

"default"	{
				return DEFAULT;
			}

"continue"	{
				return CONTINUE;
			}

"println"	{return PRINTLN;}	
{ADDOP} {
	InsertToken("ADDOP", yytext);
	return ADDOP;
}
{MULOP} {
	InsertToken("MULOP", yytext);
    return MULOP;
}
{INCOP} {
	InsertToken("INCOP", yytext);
    return INCOP;
}
{RELOP} {
	InsertToken("RELOP", yytext);
    return RELOP;
}
{DECOP} {
	InsertToken("DECOP", yytext);
        return DECOP;
    }
{LOGICOP} {
	InsertToken("LOGICOP", yytext);
    return LOGICOP;
}
"=" {
	InsertToken("ASSIGNOP", yytext);
    return ASSIGNOP;
}

"!" {
	InsertToken("NOT", yytext);
    return NOT;
}
"(" {
	InsertToken("LPAREN", yytext);
    return LPAREN;
}
")" {
	InsertToken("RPAREN", yytext);
    return RPAREN;
}
"{" {
	InsertToken("LCURL", yytext);
    return LCURL;
}
"}" {
	InsertToken("RCURL", yytext);
    return RCURL;
}
"[" {
	InsertToken("LTHIRD", yytext);
    return LTHIRD;
}
"]" {
	InsertToken("RTHIRD", yytext);
    return RTHIRD;
}
"," {
	InsertToken("COMMA", yytext);
    return COMMA;
}
";" {
	InsertToken("SEMICOLON", yytext);
    return SEMICOLON;
}
{CONST_INT} {

	InsertToken("CONST_INT", yytext);
	
    return CONST_INT;
}
{CONST_FLOAT} {

	InsertToken("CONST_FLOAT", yytext);
    return CONST_FLOAT;
}

{CONST_CHAR} {
	if(strlen(yytext)==3){
        str = string(1, yytext[1]);
   
		InsertToken("CONST_CHAR", str);
        return CONST_CHAR;
    }
	else {
		string s = EscapeCharacter(yytext + 1);
        str = s;
	}

}


{IDENTIFIER} {
	InsertToken("ID", yytext);
	return ID;
}

{DECIMAL}([.]{CONST_INT}?)+ {
	printError("Too many decimal points", yytext);
}


{DIGIT}*([.]{CONST_INT})?([eE][-+]?({DIGIT}*[.])+{CONST_INT})|{CONST_FLOAT}?([.][0-9]*)+ {
	printError("Ill formed number", yytext);
}

({CONST_INT}){IDENTIFIER} {
	printError("Invalid prefix on ID or invalid suffix on Number", yytext);
}

{MULTI_CHAR_ERROR} {
	printError("MULTI_CHAR_ERROR", yytext);
	}
	
{UNFINISHED_CHAR_ERROR} {
    printError("UNFINISHED_CHAR_ERROR", yytext);
}

"''" {
    printError(" Empty character ", yytext);
}


{SINGLELINE_COMMENT}  {	

		start_line = line_count;
		for(int i = 0; i < strlen(yytext); i++){
			if(yytext[i] == '\n'){
				line_count++;
			}
		}	
}

{MULTILINE_COMMENT}  {
		start_line = line_count;
		for(int i = 0; i < strlen(yytext); i++){
			if(yytext[i] == '\n'){
				line_count++;
			}
		}		
	
}

{UNFINISHED_COMMENT} {
		printError("Unterminated Comment", yytext);
		for(int i = 0; i < yyleng; i++){
			if(yytext[i] == '\n'){
				line_count++;
			}
		}
}


"\"" {
	str = "";
	str += yytext;
	start_line = line_count;
	BEGIN STRINGSTATE;
}
<STRINGSTATE>"\\\n"|"\\\r\n" {
	str += yytext;
	line_count++;
}

<STRINGSTATE>"\\\"" {
	str += yytext;
}

<STRINGSTATE>"\"" {
	str += yytext;
    string tmp;
    for(int i = 0; i < str.size(); i++){
        if(str[i] == '\\' && i + 1 != str.size()){
            if(str[i + 1] == '\n'){
                i++;
                continue;
            }
            if(i + 2 < str.size() && str[i + 1] == '\r' && str[i + 2] == '\n'){
                i += 2;
                continue;
            }
            string t(1, str[i]);
            t += str[i + 1];
            t = EscapeCharacter(t);
            if(t != "x"){
                tmp += t;
                i++;
            }
            continue;
        }
        
        tmp += str[i];
    }
	BEGIN INITIAL;
}

<STRINGSTATE>[^\n] {
	str += yytext;
}

<STRINGSTATE>[\n]|"\r\n" {
	printError("Unterminated String", str);
	line_count++;
	str = "";
	BEGIN INITIAL;

}

<<EOF>> { 
	return 0;
}
. {
	printError("Unrecognized character", yytext);
}
%%
int yywrap(void)
{
	return 1;
}


