%option c++ noyywrap
%x STRINGSTATE

%{

#include<bits/stdc++.h>
#include "SymbolTable.h"
using namespace std;

int line_count = 1;
int error_count = 0;
SymbolTable symTab(7);
string str;
string lexeme;
int start_line;
ofstream token_file;
ofstream log_file;

void printLog(string tokenName, string lexeme, bool multiline=false){
	int line_no = multiline ? start_line : line_count;
	log_file << "Line no " << line_no << ": Token <" <<  tokenName << "> Lexeme " << lexeme << " found" ;
	
	if(tokenName == "STRING" || tokenName == "CONST_CHAR") log_file << " --> <" << tokenName << ", " << str << ">";
	log_file << endl << endl;	
}
void printError(string errorName, string lexeme, bool multiline=false){

	error_count++;
	int line_no = multiline ? start_line : line_count;
	log_file << "Error at line no " << line_no << ": " << errorName << " " << lexeme << endl << endl;
}
void printToken(string tokenName, string key="")
{
    token_file << "<" << tokenName;
	if(key != "") token_file << ", " << key;
	token_file << "> ";
}
void insertIntoTable(string key, string type){
    if(symTab.InsertSymbol(key, type)){
        symTab.PrintallScope(log_file);
    }
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
INCOP ("++"|"--")
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
{KEYWORD} {  

	char *toUpper=(char*)malloc(sizeof(char*)*(yyleng + 1));
	int i =0;

    	while(i<yyleng)
        {toUpper[i]=yytext[i]-32;
        i++;
        }
    toUpper[i] = '\0';
   	printToken(toUpper);
	printLog(toUpper, yytext);
	free(toUpper);
}
	
{ADDOP} {
	printToken("ADDOP", yytext);
	printLog("ADDOP", yytext);
}
{MULOP} {
	printToken("MULOP", yytext);
	printLog("MULOP", yytext);
	
}
{INCOP} {
	printToken("INCOP", yytext);
	printLog("INCOP", yytext);
}
{RELOP} {
	printToken("RELOP", yytext);
	printLog("RELOP", yytext);
}
{LOGICOP} {
	printToken("LOGICOP", yytext);
	printLog("LOGICOP", yytext);
}
"=" {
	printToken("ASSIGNOP", yytext);
	printLog("ASSIGNOP", yytext);
}

"!" {
	printToken("NOT", yytext);
	printLog("NOT", yytext);
}
"(" {
	printToken("LPAREN", yytext);
	printLog("LPAREN", yytext);
}
")" {
	printToken("RPAREN", yytext);
	printLog("RPAREN", yytext);
}
"{" {
	printToken("LCURL", yytext);
	printLog("LCURL", yytext);
	symTab.Enterscope();
}
"}" {
	printToken("RCURL", yytext);
	printLog("RCURL", yytext);
	symTab.ExitScope();
}
"[" {
	printToken("LTHIRD", yytext);
	printLog("LTHIRD", yytext);
}
"]" {
	printToken("RTHIRD", yytext);
	printLog("RTHIRD", yytext);
}
"," {
	printToken("COMMA", yytext);
	printLog("COMMA", yytext);
}
";" {
	printToken("SEMICOLON", yytext);
	printLog("SEMICOLON", yytext);
}
{CONST_INT} {
	printToken("CONST_INT", yytext);
	printLog("CONST_INT", yytext);
    insertIntoTable(yytext, "CONST_INT");
	
}
{CONST_FLOAT} {
	printToken("CONST_FLOAT", yytext);
	printLog("CONST_FLOAT", yytext);
    insertIntoTable(yytext, "CONST_FLOAT");
	
}

{CONST_CHAR} {
	if(strlen(yytext)==3){
        str = string(1, yytext[1]);
        
		printLog("CONST_CHAR", yytext);
        
		printToken("CONST_CHAR", str);
        insertIntoTable(yytext, "CONST_CHAR");
	}
	else {
		string s = EscapeCharacter(yytext + 1);
        str = s;
        printLog("CONST_CHAR", yytext);
		printToken("CONST_CHAR", s);
        insertIntoTable(yytext, "CONST_CHAR");
	}

}


{IDENTIFIER} {
	printToken("ID", yytext);
	printLog("ID", yytext);
	insertIntoTable(yytext, "ID");
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
		for(int i = 0; i < strlen(yytext); i++){
			if(yytext[i] == '\n'){
				line_count++;
			}
		}	
		printLog("COMMENT", lexeme, true);
}

{MULTILINE_COMMENT}  {
		printLog("COMMENT", lexeme, true);
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
	printToken("STRING", tmp);
	printLog("STRING", str, true);
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
	symTab.PrintallScope(log_file);
	log_file << "Total lines: " << line_count << endl << "Total errors: " << error_count << endl; 
	return 0;
}
. {
	printError("Unrecognized character", yytext);
}
%%

int main(int argc, char *argv[]){
	
	if(argc != 2)
	{
		cout << "Please provide input file name and try again" << endl;
		return 0;
	}
	
	ifstream file(argv[1]);
	if(file.fail())
	{
		cout << "Cannot open specified file" << endl;
		return 0;
	}	
	token_file.open("token.txt", ios::out);
	log_file.open("log.txt", ios::out);

	yyFlexLexer *lexer = new yyFlexLexer(&file);
	lexer->yylex();
	
	
	token_file.close();
	log_file.close();
	file.close();
}

