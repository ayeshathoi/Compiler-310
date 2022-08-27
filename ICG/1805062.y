%{
#include<bits/stdc++.h>
#include "asmCode.h"
#include "SymbolTable.h"
#include "optimizer.h"
#define YYSTYPE SymbolInfo*
using namespace std;

int yyparse(void);
int yylex(void);

extern FILE *yyin;

ofstream logout;
ofstream error;
ofstream asmCodeGeneration;
extern int line_count;
extern int error_count;
extern int yylineno;
SymbolTable *symboltable; 

vector<SymbolInfo*> Dec_List;
vector<SymbolInfo*> Params_List;
vector<string> Param_List;
vector<string> argument_List;
SymbolInfo *retType;
string funcName;
vector<string> parName;
optimizer o;
asmCode Code;
string s = "main";

void yyerror(string s)
{
    logout << "Error at line " << yylineno <<": " <<s <<"\n\n";
    error  << "Error at line " << yylineno <<": " <<s <<"\n\n";
    error_count++;
}

bool typeCheck(string name, string type, string actual)
{
    if(type != actual)
    {
        string s = "Type mismatch, " + name +" is not a " + actual;  
        yyerror(s);
        return true;
    }
    return false;
}

bool declareNot(SymbolInfo *current, string name ,string type)
{
    if(current == NULL && type == "statement" || current == NULL && type == "variable")
    {	
        string s = "Undeclared variable " + name;
        yyerror(s);
        return true;
    }
    else if(current == NULL && type == "factor")
    {
        string s = "Undefined reference to "+ name;
        yyerror(s); 
        return true;
    }
    return false;
}
bool listcheck(vector<string> arg,vector<string> pm)
{
    if(pm.size() != arg.size()){
        string s = "Total number of arguments mismatch in function ";
        yyerror(s);
        return true;
    }
    for(int i = 0; i < arg.size(); i++){
        if(arg[i] != pm[i]){                
            string s = to_string(i + 1) + "th argument mismatch in function";
            yyerror(s);
            return true;
        }
    }
    return false;
}

bool vectorcheck(SymbolInfo *current, vector<string> found,vector<string> actual)
{
    if(found != actual) 
    {
        string s = "Conflicting types for " + current->name;
           yyerror(s);
           return true;
    }
    return false;
}

void functionProcess(vector<SymbolInfo*> declist, string ret,bool isParameter)
{
    int i =0;
    if(ret == "void"){
        yyerror("Variable type cannot be void");
        return;
    }			
    while(i<declist.size())
    {
        SymbolInfo *current = symboltable->LookupSymbolInCurrent(declist[i] -> name); 
        declist[i]->returnType = ret; 
        
        if(current)
        {
            string s = "Multiple declaration of "+declist[i]->name;
            yyerror(s);
        }	
        else{
            symboltable->InsertSymbol(declist[i]->name, declist[i]->type,declist[i]->returnType, declist[i]->variableType);
            string s;
            if(declist[i]->variableType=="array")
            {
                s = declist[i]->name + symboltable->getCurrentScopeName() + " DW " + declist[i]->intToStr(declist[i]->getArraySize()) + " DUP(?)";
            }
            else s = declist[i]->name + symboltable->getCurrentScopeName() + " DW ?";
            if(isParameter==false)
                {
                    Code.varList.push_back(s);
                }
        }
        i++;
    }

    
}
void paramfuncProcess(vector<SymbolInfo*> p, string name)
{
    int i = 0;
    while(i<p.size())
    {
        if(p[i]->name == "") yyerror(string(to_string(i + 1) + "th parameter's name not given in function definition of ") + name);
        else
        {
            SymbolInfo *current = symboltable->LookupSymbolInCurrent(p[i]->name); 
            if(current) {	
                string s = "Multiple declaration of " + p[i] -> name + " in parameter"; 
                yyerror(s);
            }else
                symboltable->InsertSymbol(p[i]->name, p[i]->type, p[i]->returnType, p[i]->variableType);
        }
        i++;
    }
}
bool voidCheck(string s,string type)
{
    if(s=="void")
    {
        string text = "Void expression used in " + type;
        yyerror(text);

        return true;
    }
    return false;
}


bool defineNot(SymbolInfo* cur)
{
    if(cur != NULL && cur -> defined)
    {
        string s = "Multiple definition of " + cur->name;  
        yyerror(s);
        return true;
    }
    return false;
}

bool variableCheck(string name,string variabletype,string type)
{
    if(variabletype != type)
    {
        string s = "Multiple declaration of " + name;
        yyerror(s);
        return true;
    }
    return false;
}

string getStackPointer(string variableName) {
        string stackPointer = "#";
        for(int i = 0, j = Param_List.size()-1; j>=0; j--, i++) {
                if(parName[j]== variableName) {
                        stackPointer = "[BP+" + to_string(4 + 2*i) + "]";
                        break;
                }
        }
        return stackPointer;
}
%}

%token IF ELSE FOR WHILE DO INT CHAR FLOAT VOID PRINTLN BREAK DOUBLE SWITCH CASE DEFAULT 
%token RETURN CONTINUE  NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD 
%token COMMA SEMICOLON ADDOP MULOP INCOP DECOP LOGICOP RELOP ASSIGNOP
%token ID CONST_INT CONST_FLOAT CONST_CHAR


%left COMMA
%right ASSIGNOP
%left LOGICOP
%left RELOP
%left ADDOP
%left MULOP
%right INCOP DECOP NOT
%left LPAREN RPAREN LTHIRD RTHIRD LCURL RCURL

%right LOWER_THAN_ELSE ELSE


%%

start : program
    {
        logout<<"Line "<<yylineno<<": "<<" start : program\n\n";
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol);
        string asmCodeTobeGenerated =".MODEL SMALL\n.STACK 100H\n\n.DATA\nCR EQU 0DH\nLF EQU 0AH\nNEWLN DB CR, LF, '$'\n";

        asmCodeTobeGenerated += Code.Comment("Variables -> ");
        for(string str: Code.varList)  
            asmCodeTobeGenerated += str + "\n";
        
        Code.varList.clear();
                

        asmCodeTobeGenerated += Code.Comment("Temporal Variables -> ");
        
        for(string str: Code.tempList) 
            asmCodeTobeGenerated += str + "\n";
        
        Code.tempList.clear();
               
        asmCodeTobeGenerated += "\n";

        asmCodeTobeGenerated += ".CODE\n\nMAIN PROC\n; initialize_DS\nMOV AX, @DATA\nMOV DS, AX\n\n" + Code.Comment("Main Code Starts From here\n") + Code.mainCode;
        asmCodeTobeGenerated += "\nDOS_EXIT:\nMOV AH, 4CH\nINT 21H\nMAIN ENDP\n\n" + Code.Comment("extra procedues here\n");

        asmCodeTobeGenerated = Code.returnDelete(asmCodeTobeGenerated, "DOS_EXIT");
        asmCodeGeneration << asmCodeTobeGenerated << endl;
        asmCodeTobeGenerated.clear();

        ifstream in;
        in.open("1805062_print_procedure.asm");

        while(getline(in, asmCodeTobeGenerated)) 
            asmCodeGeneration << asmCodeTobeGenerated << endl;
        in.close();

        string str  ;
        for(int i = 0; i < Code.FuncList.size(); i++)
        {
                str += Code.asmProcedure(Code.FuncList[i]);
        }

        asmCodeGeneration << str << endl << "END MAIN" << endl;
    }
    ;

program : program unit 
    {
        logout<<"Line "<<yylineno<<": "<<" program : program unit\n\n";
        
        string symbol = $1->name + symbol += "\n" + $2->name; 
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    | unit
    {
        logout<<"Line "<<yylineno<<": "<<" program : unit\n\n";
        
        string symbol = $1->name; 
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    
    | program error
    {
        $$ = $1;
        logout<<$$ -> name<<"\n\n";
    }
    ;
    
unit : var_declaration
    {
        logout<<"Line "<<yylineno<<": "<<" unit : var_declaration\n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    | func_declaration
    {
        logout<<"Line "<<yylineno<<": "<<" unit : func_declaration\n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo($1->name);
        
        logout<<symbol<<"\n\n";
    }
    | func_definition
    {	
         logout<<"Line "<<yylineno<<": "<<" unit : func_definition\n\n";
         
         string symbol = $1->name;
         $$ = new SymbolInfo(symbol);
         
        logout<<symbol<<"\n\n";
    }
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
        
        
        string symbol = $1->name + " " + $2->name + "(" + $4->name  + ");"; 
                
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
        
        SymbolInfo* current = symboltable->LookupSymbolInCurrent($2->name);
        if(current)
        {
            if(!variableCheck(current->name,current->variableType,"function")) 
            {
                if(!vectorcheck($2, Param_List, current -> parameterList)){
                    yyerror(string("Multiple declaration of ") + $2 -> name); 
                }
            }  	 	
        }
        else{
            symboltable->InsertSymbol($2->name, "ID", $1->name, "function", Param_List);
                      
        }
        Params_List.clear();
        parName.clear();
        Param_List.clear();
        
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
        
        string symbol = $1->name + " " + $2->name + "();";  
        $$ = new SymbolInfo(symbol);
        
        SymbolInfo* current = symboltable->LookupSymbolInCurrent($2->name); 
        if(current){
            if(!variableCheck(current->name,current->variableType,"function")){	
                if(!vectorcheck($2, Param_List,current -> parameterList)){
                    yyerror(string("Multiple declaration of ") + $2 -> name); 
                } 
            }
        }
        else{
            symboltable->InsertSymbol($2->name, "ID", $1->name, "function", Param_List);
                      
        }
        logout<<symbol<<"\n\n";
    }
    ;
         
func_definition : type_specifier ID LPAREN parameter_list RPAREN
    {
        funcName = $2 -> name;
        SymbolInfo *current = symboltable->LookupSymbolInCurrent($2->name);
        if(current){
            if(!variableCheck(current->name,current->variableType,"function"))
            {
                if(current -> getReturnType() != $1 -> name){ 
                     yyerror(string("Return type mismatch with function declaration in function ") + funcName);
                }
                if(!vectorcheck(current, Param_List, current -> parameterList))
                    if(!defineNot(current)) 
                        current->defined = true;
            }
        }
        else{

            symboltable->InsertSymbol($2->name, "ID", $1->name, "function", Param_List, true);

        }
       
        retType = $1;
    } compound_statement  
    {
                      
        logout<<"Line "<<yylineno<<": "<<" func_definition :  type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n"<<$$->name;
          
        string symbol = $1->name + " " + $2->name + "(" + $4->name + ")" + $7->name; 
        $$ = new SymbolInfo(symbol);
 
        
        retType = NULL;

        string asmFuncCode = $7->getAsmCode();

        int paramSize = Param_List.size();
                
        if($2->name == "main") {
                 Code.mainCode = $7->getAsmCode();       
        }
        else if($2->name!="main"){
               for(int i = 0; i < Param_List.size(); i++)  {
                     asmFuncCode = Code.Comment(parName[i] + " => " + getStackPointer(parName[i])) + asmFuncCode;
             }
            
        Code.insertFunctionToList($2->name, asmFuncCode, Param_List.size());
                    
        }
        
        if($2->name == "main") {
                Code.mainCode = $7->getAsmCode();   
                }
        logout<<symbol<<"\n\n";

        funcName = "";
        Param_List.clear();
        Params_List.clear();
        parName.clear();
    }
    | type_specifier ID LPAREN RPAREN
    {
        funcName = $2 -> name;
        SymbolInfo *current = symboltable->LookupSymbolInCurrent($2->name);
        if(current)
        {
            if(!variableCheck(current->name,current->variableType,"function"))
            {
                if(current -> getReturnType() != $1 -> name){ 
                     yyerror(string("Return type mismatch with function declaration in function ") + funcName);
                }
                if(!vectorcheck(current, Param_List, current -> parameterList))
                    if(!defineNot(current))
                        current->defined = true;
            }
        }
        
        else{
            symboltable->InsertSymbol($2->name, "ID", $1->name, "function", Param_List, true);
        }
        
        retType = $1;
        
    } compound_statement
    {
        logout<<"Line "<<yylineno<<": "<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
        
        string symbol = $1->name + " " + $2->name + "()" + $6->name;       
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";

        string asmFuncCode = $6->getAsmCode();
        
        if($2->name == "main") 
             Code.mainCode = $6->getAsmCode();        
                
        else if($2->name!="main") 
        {

        for(int i = 0; i < Param_List.size(); i++)  
            asmFuncCode = Code.Comment(parName[i] + " => " + getStackPointer(parName[i])) + asmFuncCode;

        Code.insertFunctionToList($2->name, asmFuncCode, Param_List.size());

        }

        retType = NULL;
        funcName = "";
        Param_List.clear();
        Params_List.clear();
        parName.clear();

    }
    
    ;	

parameter_list  : parameter_list COMMA type_specifier ID
    {
        logout<<"Line "<<yylineno<<": "<<" parameter_list : parameter_list COMMA type_specifier ID\n\n";\
        
        Param_List.push_back($3->name);
        parName.push_back($4->name);
        
        string symbol = $1->name + "," + $3->name + " " + $4->name;      
        $$ = new SymbolInfo(symbol);
        $4->variableType = "variable";
        $4->returnType = $3->name;
        Params_List.push_back($4);
        
        logout<<symbol<<"\n\n";
        
    }
    | parameter_list COMMA type_specifier
    {
        logout<<"Line "<<yylineno<<": "<<" parameter_list : parameter_list COMMA type_specifier\n\n";
        
        Param_List.push_back($3->name);
        
        string symbol = $1->name + "," + $3->name;            
                
        $$ = new SymbolInfo(symbol);
        SymbolInfo *newNode = new SymbolInfo("", "ID");
        newNode->variableType = "variable";
        newNode->returnType = $3->name;
        Params_List.push_back(newNode);
        
        logout<<symbol<<"\n\n";
        

    }
    | type_specifier ID
    {
        logout<<"Line "<<yylineno<<": "<<" parameter_list : type_specifier ID\n\n";
        
        Param_List.push_back($1->name);
        parName.push_back($2->name);
        
        string symbol = $1->name  +  " " + $2->name;  
        
        $$ = new SymbolInfo(symbol);
        $2->variableType = "variable";
        $2->returnType = $1->name;
        Params_List.push_back($2);
        
        logout<<symbol<<"\n\n";

    }
    | type_specifier
    {
        logout<<"Line "<<yylineno<<": "<<" parameter_list : type_specifier\n\n";
        
        Param_List.push_back($1->name);
        
        string symbol = $1->name ;
        $$ = new SymbolInfo(symbol);
        
        SymbolInfo *newNode = new SymbolInfo("", "ID");
        newNode->variableType = "variable";
        newNode->returnType = $1->name;
        Params_List.push_back(newNode);
        
        logout<<symbol<<"\n\n";

    }
    
    | parameter_list error
    {
        $$ = $1;
        logout<<$$ -> name<<"\n\n";
    }
    ;

compound_statement: LCURL
    {				
        symboltable->Enterscope();
        paramfuncProcess(Params_List, funcName); 

    } statements RCURL
    {
        string symbol = "{\n"+$3->name+"\n}";
        $$ = new SymbolInfo(symbol, "");
        $$->setAsmCode($3->getAsmCode());

        logout<<symbol<<"\n\n"; 
        
        symboltable->PrintallScope(logout); 
        symboltable->ExitScope();

    }
    | LCURL
    {
        symboltable->Enterscope();
        paramfuncProcess(Params_List, funcName);
        
    } RCURL
    {
        string symbol = "{}";		//{}
        $$ = new SymbolInfo(symbol, "");
        
        logout<<symbol<<"\n\n"; 
        
        symboltable->PrintallScope(logout);
        symboltable->ExitScope();   
    }
    ;
             
var_declaration : type_specifier declaration_list SEMICOLON
    {
             
        logout<<"Line "<<yylineno<<": "<<" var_declaration: type_specifier declaration_list SEMICOLON\n\n";
                
        string symbol = $1->name + " " + $2->name + ";";
        $$ = new SymbolInfo(symbol);
        logout<<symbol<<"\n\n";
        
        functionProcess(Dec_List, $1-> name,false);
        
        Dec_List.clear(); 
    }
    ;
          
type_specifier	: INT
    {
        logout<<"Line "<<yylineno<<": "<<" type_specifier : INT\n\n";
        $$ = new SymbolInfo("int");
        logout<<"int"<<"\n\n";
    }
    | FLOAT
    {
        logout<<"Line "<<yylineno<<": "<<" type_specifier : FLOAT\n\n";
        $$ = new SymbolInfo("float");
        logout<<"float"<<"\n\n";
    }
    | VOID
    {
        logout<<"Line "<<yylineno<<": "<<" type_specifier : VOID\n\n";
        $$ = new SymbolInfo("void");
        logout<<"void"<<"\n\n";
    }
    ;
    
declaration_list: declaration_list COMMA ID
    {
        logout<<"Line "<<yylineno<<": "<<" declaration_list : declaration_list COMMA ID\n\n";
            
        string symbol = $1->name + "," + $3->name;
        
        $$ = new SymbolInfo(symbol);
                    
        $3->variableType = "variable";
        Dec_List.push_back($3);
            
        logout<<symbol<<"\n\n";
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        
        logout<<"Line "<<yylineno<<": "<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n";
        
        string symbol = $1->name + "," + $3->name + "[" + $5->name + "]";
        $3->variableType = "array";
        $3->setArraySize(stoi($5->name));
        $$ = new SymbolInfo(symbol);

        Dec_List.push_back($3);

        logout<<symbol<<"\n\n";
    }
    | ID
    {	
        logout<<"Line "<<yylineno<<": "<<" declaration_list : ID\n\n";
            
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol,"ID");
        Dec_List.push_back($1);
        $1->variableType = "variable";
            
        logout<<symbol<<"\n\n";
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        logout<<"Line "<<yylineno<<": "<<" declaration_list :  ID LTHIRD CONST_INT RTHIRD\n\n";
        
        string symbol = $1->name + "[" + $3->name + "]";
        $1->variableType = "array";	
        $1->setArraySize(stoi($3->name ));
        $$ = new SymbolInfo(symbol);
        
        Dec_List.push_back($1);

        logout<<symbol<<"\n\n";
    }
    | declaration_list error
    {
        $$ = $1;
        logout<<$$ -> name<<"\n\n";
    }
    ;
      
statements : statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : var_declaration\n\n";
            
        string symbol = $1->name;
        $$ = new SymbolInfo($1->name);
        $$->setAsmCode($1->getAsmCode());

        logout<<symbol<<"\n\n";

    }
    | statements statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : statements statement\n\n";
            
        string symbol = $1->name + "\n" + $2->name;
        
        $$ = new SymbolInfo(symbol);
        $$->setAsmCode($1->getAsmCode() + $2->getAsmCode());

        logout<<symbol<<"\n\n";
        
    }
    | statements error
    {
        $$ = $1;
        logout<<$$ -> name<<"\n\n";
    }
    ;
       
statement : var_declaration
    {
        logout<<"Line "<<yylineno<<": "<<" statement : var_declaration\n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol);
    
        logout<<symbol<<"\n\n";
        
    }
    | expression_statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : expression_statement\n\n";
            
        string symbol = $1->name; 		
        $$ = new SymbolInfo(symbol);
        $$->returnType= "void";
        $$->setAsmCode($1->getAsmCode());
        logout<<symbol<<"\n\n";
    }
    | compound_statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : compound_statement\n\n";
            
        string symbol = $1->name; 		
        $$ = new SymbolInfo(symbol);
        $$->setAsmCode($1->getAsmCode());    
        logout<<symbol<<"\n\n";
        
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
                
        string symbol = "for(" + $3->name + $4->name + $5->name + ")" + $7->name;   
        string endLoop = Code.newLabel();
        string beginLoop = Code.newLabel();
        string asmCodeTobeGenerated = Code.Comment("--- FOR LOOP ---") + Code.Comment("INITIATING LOOP") + $3->getAsmCode() + Code.LineLabel("Label",beginLoop);                             
        asmCodeTobeGenerated += Code.Comment("LOOP BREAK CONDITION") + $4->getAsmCode() + Code.CmpJump("Cmp",$4->getValueRep(), "0") + Code.CmpJump("Jump","JE", endLoop, "BREAK WHEN BREAK-CONDITION IS TRUE");
        asmCodeTobeGenerated += $7->getAsmCode() + $5->getAsmCode() + Code.CmpJump("Jump","JMP", beginLoop, "JMP TO NEXT ITERATION") + Code.LineLabel("Label",endLoop) + Code.Comment("--- END FOR ---");


        $$ = new SymbolInfo(symbol);
        $$->setReturnType("void");

        $$->setAsmCode(asmCodeTobeGenerated);
        
        logout<<symbol<<"\n\n";
        
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE 
    {
        logout<<"Line "<<yylineno<<": "<<" statement : IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE\n\n";
                
        string symbol = "if(" + $3->name + ")\n" +  $5->name; 
        
        $$ = new SymbolInfo(symbol);
    
        string label = Code.newLabel();
        string asmCodeTobeGenerated = Code.Comment("--- if(" + $3->name + ") ---") + $3->getAsmCode() + Code.CmpJump("Cmp",$3->getValueRep(), "0") + Code.CmpJump("Jump","JE", label);
        asmCodeTobeGenerated += Code.Comment("--- INSIDE IF ---") + $5->getAsmCode()+Code.LineLabel("Label",label) + Code.Comment("--- END IF ---");
        
        if(voidCheck($3->getReturnType(),"if"))
            $$->setReturnType("error");
        $$->setAsmCode(asmCodeTobeGenerated);

        logout<<symbol<<"\n\n";            
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
        
        string symbol = "if(" + $3->name + ")" + $5->name + "\nelse\n" + $7->name;
        
        $$ = new SymbolInfo(symbol);
            
        string endIf = Code.newLabel();
        string elseLabel = Code.newLabel();
        string asmCodeTobeGenerated = Code.Comment("--- if(" + $3->name + ") ---") + $3->getAsmCode() +Code.CmpJump("Cmp",$3->getValueRep(), "0");
        asmCodeTobeGenerated += Code.CmpJump("Jump","JE", elseLabel, "ELSE CONDITION") + Code.Comment("--- INSIDE IF ---") + $5->getAsmCode() + Code.CmpJump("Jump","JMP", endIf);
        asmCodeTobeGenerated += Code.LineLabel("Label",elseLabel) + Code.Comment("--- ELSE ---") + $7->getAsmCode() + Code.LineLabel("Label",endIf);
        asmCodeTobeGenerated += Code.Comment("--- END IF ---");

        if(voidCheck($3->getReturnType(),"if"))
            $$->setReturnType("error");
        
        $$->setAsmCode(asmCodeTobeGenerated);
        logout<<symbol<<"\n\n";
    }
    | WHILE LPAREN expression RPAREN statement
    {
        $$ = new SymbolInfo("while("+$3->name+")\n"+$5->name);
        logout<<"Line "<<yylineno<<": "<<" statement : WHILE LPAREN expression RPAREN statement\n\n";
            
        string symbol = "while(" + $3->name + ")" + $5->name;
             
        $$ = new SymbolInfo(symbol);
        $$->setReturnType("void");

        string beginLoop = Code.newLabel();
        string endLoop = Code.newLabel();
        string asmCodeTobeGenerated = Code.Comment("--- while(" + $3->name + ")---")+Code.LineLabel("Label",beginLoop)+$3->getAsmCode();
        asmCodeTobeGenerated += Code.CmpJump("Cmp",$3->getValueRep(), "0", "LOOP BREAK CONDITION")+Code.CmpJump("Jump","JE", endLoop, "BREAK")+$5->getAsmCode();
        asmCodeTobeGenerated += Code.CmpJump("Jump","JMP", beginLoop)+Code.LineLabel("Label",endLoop)+Code.Comment("--- END WHILE ---");
  
        $$->setAsmCode(asmCodeTobeGenerated);
           
        logout<<symbol<<"\n\n";

    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        
        logout<<"Line "<<yylineno<<": "<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
            
        string symbol = "println(" +  $3->name +");";  
        $$ = new SymbolInfo(symbol);
        $$->setReturnType("error");

        SymbolInfo *current = symboltable->LookupSymbol($3->name);
        if(!declareNot(current,$3->name,"statement"))
            typeCheck(current -> name, current->variableType, "variable");	
        
        logout<<symbol<<"\n\n";
        string valueRep = $3->name + symboltable->getScopeName($3->name);
        string asmCodeTobeGenerated = Code.Comment(symbol) + Code.twoVarOperation("MOV","AX", valueRep)+Code.LineLabel("LINE","CALL PRINT_INT");
        asmCodeTobeGenerated += Code.LineLabel("LINE","LEA DX, NEWLN")+Code.LineLabel("LINE","MOV AH, 9")+Code.LineLabel("LINE","INT 21H");
        $$->setAsmCode(asmCodeTobeGenerated);
            
    }
    | RETURN expression SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" statement : RETURN expression SEMICOLON\n\n";
        
        string symbol = "return " + $2->name+";";
        $$ = new SymbolInfo(symbol);
        $$->setReturnType($2->getReturnType());
        string asmCodeTobeGenerated = $2->getAsmCode() + Code.LineLabel("LINE","RETURN " + $2->getValueRep());
        $$->setAsmCode(asmCodeTobeGenerated);

        if(retType == NULL)                     
        {
            yyerror("Return statement is not in function scope");
        }else if(!(retType -> name == "float" && $2 -> getReturnType() == "int") && retType -> name != $2 -> getReturnType()){
           yyerror("Return type mismatch");
        }

        logout<<symbol<<"\n\n";

    }
    ;
      
expression_statement : SEMICOLON	
    {
        
        logout<<"Line "<<yylineno<<": "<<"expression_statement : SEMICOLON\n\n";
        string symbol = ";" ; 
        $$ = new SymbolInfo(symbol);
        logout<<symbol<<"\n\n";
    }		
    | expression SEMICOLON 
    {
        logout<<"Line "<<yylineno<<": "<<"expression_statement : expression SEMICOLON \n\n";
        string symbol = $1->name+";" ;  
        $$ = new SymbolInfo(symbol);
        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());
        
        logout<<symbol<<"\n\n";

    }		
    ;

variable: ID
    {
        logout<<"Line "<<yylineno<<": "<<"variable : ID \n\n";
        
        SymbolInfo *current = symboltable->LookupSymbol($1->name);	
        
        string symbol = $1->name;
        if(declareNot(current,$1->name,"variable") || typeCheck(current -> name, current->variableType, "variable"))
        {	
            $$ = new SymbolInfo(symbol);
            $$->setReturnType("error");
        }
        else 
        {
            $$ = new SymbolInfo(symbol, "", current->returnType, current -> variableType);
            $$->setArraySize(current->getArraySize());
                
        }

        string valueRep;
        bool  in = Param_List.size() > 0;
        if(in)
            valueRep = getStackPointer($1->name); 
        else valueRep = $1->name + symboltable->getScopeName($1->name);
                
        if(valueRep == "#")
             valueRep = $1->name + symboltable->getScopeName($1->name);
        $$->setValueRep(valueRep);

        logout<<symbol<<"\n\n";

    }
    | ID LTHIRD expression RTHIRD
    {
    
        logout<<"Line "<<yylineno<<": "<<"variable : ID LTHIRD expression RTHIRD \n\n";
        
        string symbol = $1->name + "["+$3->name+"]";
        SymbolInfo *current = symboltable->LookupSymbol($1->name);

        
        if(declareNot(current,$1->name,"array")||typeCheck(current -> name, current->variableType, "array"))
            {
                $$ = new SymbolInfo(symbol, "");
                $$->setReturnType("error");
            }
        else
        {
            if($3->returnType != "int") 
                yyerror("Array index not integer");
            $$ = new SymbolInfo(symbol, "array", current->returnType, current->variableType);
            $$->setArraySize(current->getArraySize());
        }
     
        string asmCodeTobeGenerated = $3->getAsmCode() + Code.twoVarOperation("MOV","BX", $3->getValueRep()) + Code.twoVarOperation("ADD","BX", "BX");
        
        $$->setAsmCode(asmCodeTobeGenerated);
                
        string valueRep = $1->name + symboltable->getScopeName($1->name);
        $$->setValueRep(valueRep);

        logout<<symbol<<"\n\n";
    }
    ;	 
expression : logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<" expression : logic_expression \n\n";
        
        string symbol = $1->name;	
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

        logout<<symbol<<"\n\n";
        
    }
    | variable ASSIGNOP logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<" expression : variable ASSIGNOP logic_expression \n\n";

        bool t = voidCheck($3->getReturnType(),"expression");
            
        if(t)
            $$->setReturnType("error");
        if(t|| $1 -> returnType == "float" && $3->returnType == "int")
            ;
        else if($1 -> variableType == "variable" && $1->returnType != $3->returnType) 
        {
            yyerror("Type Mismatch");
        }
            
        string symbol = $1->name + " = " + $3 -> name;
        $$ = new SymbolInfo(symbol, "", $1->returnType);

        string asmCodeTobeGenerated = $3->getAsmCode() + $1->getAsmCode() + Code.Comment(symbol) + Code.twoVarOperation("MOV","AX", $3->getValueRep());
        if($1->type == "array") {
                string temp = Code.newTemp();
                asmCodeTobeGenerated += Code.Comment(temp + " <- " + $1->name) + Code.twoVarOperation("MOV",$1->getValueRep() + "[BX]", "AX") + Code.twoVarOperation("MOV",temp, "AX");
                $$->setValueRep(temp);
        }
        
        else {
                asmCodeTobeGenerated += Code.twoVarOperation("MOV",$1->getValueRep(), "AX");
                $$->setValueRep($1->getValueRep());
        }
        $$->setAsmCode(asmCodeTobeGenerated);

   }
   ;
        
            
logic_expression : rel_expression
    {
        logout<<"Line "<<yylineno<<": "<<" logic_expression : rel_expression \n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo($1->name, "", $1->returnType);
        
        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

        logout<<symbol<<"\n\n";

    }	
    | rel_expression LOGICOP rel_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" logic_expression : rel_expression LOGICOP rel_expression \n\n";
        
        string symbol = $1->name +" "+$2->name+" "+$3->name;	
        $$ = new SymbolInfo(symbol, "", "int");

        if(voidCheck($1->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        if(voidCheck($3->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        $$->setReturnType("int");  

        
        logout<<symbol<<"\n\n";

        string temp = Code.newTemp();
        string asmCodeTobeGenerated = $1->getAsmCode() + $3->getAsmCode();

        if($2->name == "||") 
                asmCodeTobeGenerated += Code.MULDIVLOGIC("LogicOr",temp, $1->getValueRep(), $3->getValueRep());
        if($2->name == "&&") 
                asmCodeTobeGenerated += Code.MULDIVLOGIC("LogicAnd",temp, $1->getValueRep(), $3->getValueRep());

        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

    }
    ;
        
            
rel_expression	: simple_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" rel_expression	: simple_expression  \n\n";
        
        string symbol = $1->name;	
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";

        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());
        
    }
    | simple_expression RELOP simple_expression
    {
        logout<<"Line "<<yylineno<<": "<<" rel_expression	: simple_expression RELOP simple_expression \n\n";
        
        string jumpLabel;
        if($2->name == "<")
            jumpLabel = "JL";
        else if($2->name == "<=")     
            jumpLabel = "JLE";
        else if($2->name == ">")      
            jumpLabel = "JG";
        else if($2->name == ">=")     
            jumpLabel = "JGE";
        else if($2->name == "==")     
            jumpLabel = "JE";
        else if($2->name == "!=")     
            jumpLabel = "JNE";

        
        string symbol = $1->name +" "+$2->name+" "+$3->name;		
        
        $$ = new SymbolInfo(symbol);

        if(voidCheck($1->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        if(voidCheck($3->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        $$->setReturnType("int");
        
        logout<<symbol<<"\n\n";


        string temp = Code.newTemp();

        string asmCodeTobeGenerated = $1->getAsmCode() + $3->getAsmCode() + Code.Comment(temp + " <- " + symbol) + Code.LineLabel("LINE","MOV " + temp + ", 1", "CONSIDERING " + symbol + " TO BE TRUE BY DEFAULT") ;
        asmCodeTobeGenerated += Code.twoVarOperation("MOV","AX", $1->getValueRep()) + Code.CmpJump("Cmp","AX", $3->getValueRep(), symbol);

        string labelName = Code.newLabel();
        string comment = "Assuming Next Line as True"; 
        asmCodeTobeGenerated += Code.CmpJump("Jump",jumpLabel, labelName, comment) + Code.twoVarOperation("MOV",temp, "0") + Code.LineLabel("Label",labelName);

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);
    }
    ;
                
simple_expression :term
    {
        logout<<"Line "<<yylineno<<": "<<" simple_expression : term \n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

        logout<<symbol<<"\n\n";
    }
    | simple_expression ADDOP term
    {
            
        logout<<"Line "<<yylineno<<": "<<" simple_expression : simple_expression ADDOP term \n\n";
        
        string symbol = $1->name + " "+$2->name +" "+$3->name;        
        string temp = Code.newTemp();
        string asmCodeTobeGenerated = $1->getAsmCode() + "\n" + $3->getAsmCode() + "\n" + Code.Comment(temp + " <- " + symbol) + Code.twoVarOperation("MOV","AX", $1->getValueRep());
        if($2->name == "+") 
            asmCodeTobeGenerated += Code.twoVarOperation("ADD","AX", $3->getValueRep());
        else   
            asmCodeTobeGenerated += Code.twoVarOperation("SUB","AX", $3->getValueRep());
            
        asmCodeTobeGenerated += Code.twoVarOperation("MOV",temp, "AX");

        if(voidCheck($1->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        if(voidCheck($3->getReturnType(),"expression"))
            $$->setReturnType("error");

        else if($1->returnType == "float" || $3->returnType == "float") 
            $$ = new SymbolInfo(symbol, "", "float");
        else
            $$ = new SymbolInfo(symbol, "","int");
        
        logout<<symbol<<"\n\n";


        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);


    } 
    ;
                    
term :	unary_expression
    {
        logout<<"Line "<<yylineno<<": "<<" term :	unary_expression \n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo($1->name, "", $1->returnType);
        
        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

        logout<<symbol<<"\n\n";

    }
    |  term MULOP unary_expression
    {
        
        logout<<"Line "<<yylineno<<": "<<" term : term MULOP unary_expression\n\n";
        
        string symbol = $1->name + " "+$2->name + " "+$3->name;	
                         
        $$ = new SymbolInfo(symbol,"", "int"); 
        logout<<symbol<<"\n\n";
        bool check = true;
        string str = $3->name;
        
        for(int i=0;i<str.size();i++)
        {
            if(str[i]!='0')
                check = false;
        }

        string temp = Code.newTemp();

        string asmCodeTobeGenerated = $1->getAsmCode() + $3->getAsmCode() + Code.Comment(temp + " <- " + symbol);
        string operand1 = $1->getValueRep();
        string operand2 = $3->getValueRep();

        bool numberTest = true;
        for(char c: $3->getValueRep()) 
            if(!('0' <= c and c <= '9')) 
                numberTest = false;

        if(numberTest) {
            asmCodeTobeGenerated += Code.twoVarOperation("MOV","CX", $3->getValueRep());
            operand2 = "CX";
        }

        if($2->name == "*")  
                asmCodeTobeGenerated += Code.MULDIVLOGIC("MUL",temp, operand1, operand2);
        else  asmCodeTobeGenerated += Code.MULDIVLOGIC("DIV",temp, operand1, operand2, $2->name == "/");
                
            
        if(voidCheck($1->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        if(voidCheck($3->getReturnType(),"expression"))
            $$->setReturnType("error");
        else{
            
            if($1->getReturnType()=="float" || $3->getReturnType()=="float")
                $$->setReturnType("float");
            if($2->getName()=="/")
            {
                if(check)
                {
                    yyerror("Division by Zero");
                }
            }
            if($2->getName()=="%")
            {
                if($$->getReturnType()=="float")
                {
                    yyerror("Non-Integer operand on modulus operator");
                    $$->setReturnType("int");
                }
                if(check)
                {
                    yyerror("Modulus by Zero");
                }
                
            }
        }

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);


    }
    ;

unary_expression : ADDOP unary_expression  
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : ADDOP unary_expression\n\n";
        
        string asmCodeTobeGenerated = $2->getAsmCode();
        if($1->name == "-") 
                asmCodeTobeGenerated += Code.oneVarOperation("NEG",$2->getValueRep());  

        if(voidCheck($2->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        string symbol = $1->name;		//Addop +,-
        symbol += " "+$2->name; 		//unary_expression
        $$ = new SymbolInfo(symbol, $2->getType(), $2 -> returnType);
        
        logout<<symbol<<"\n\n";

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep($2->getValueRep());
        
    }
    | NOT unary_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : NOT unary_expression\n\n";
        
        if(voidCheck($2->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        string symbol = "!" + $2->name; 

        string l1 = Code.newLabel();
        string l2 = Code.newLabel();
        string temp = Code.newTemp();
                
        string asmCodeTobeGenerated = $2->getAsmCode() + Code.Comment(temp + " <- " + symbol) + Code.CmpJump("Cmp",$2->getValueRep(), "0", "if " + $2->name + " == 0");
        asmCodeTobeGenerated += Code.CmpJump("Jump","JE", l1) + Code.twoVarOperation("MOV",temp, "1") + Code.CmpJump("Jump","JMP", l2)+ Code.LineLabel("Label",l1, $2->name + " == 0");
        asmCodeTobeGenerated += Code.twoVarOperation("MOV",temp, "0") + "\n" + Code.LineLabel("Label",l2);

        $$ = new SymbolInfo(symbol , $2->getType(), "int"); 
        logout<<symbol<<"\n\n";

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);

        
    }
    | factor
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : factor\n\n";
        
        string symbol = $1->name ;	
        $$ = new SymbolInfo(symbol , $1->getType(), $1 -> returnType);
        

        $$->setAsmCode($1->getAsmCode());
        $$->setValueRep($1->getValueRep());

        logout<<symbol<<"\n\n";
    }
    ;

factor : variable
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: variable\n\n";
        
        string symbol = $1->name ;	
        $$ = new SymbolInfo(symbol, $1->getType(), $1->returnType);
        
        logout<<symbol<<"\n\n";

        if($1->type == "array") {
            string temp = Code.newTemp();
            string asmCodeTobeGenerated = $1->getAsmCode() + Code.twoVarOperation("MOV","AX", $1->getValueRep() + "[BX]") + Code.twoVarOperation("MOV",temp, "AX");
            asmCodeTobeGenerated = Code.Comment(temp + " = " + symbol) + asmCodeTobeGenerated;

            $$->setAsmCode(asmCodeTobeGenerated);
            $$->setValueRep(temp);
        }
        
        else {
            $$->setAsmCode($1->getAsmCode());
            $$->setValueRep($1->getValueRep());
        }
    }
    | ID LPAREN argument_list RPAREN
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: ID LPAREN argument_list RPAREN\n\n";


        string symbol = $1->name+"(" + $3->name+")";			

        string temp = Code.newTemp();
        string asmCodeTobeGenerated = Code.Comment(temp + " <- " + symbol) + $3->getAsmCode();
        for(string str: Code.argList) 
                asmCodeTobeGenerated += Code.oneVarOperation("PUSH",str);                  
        asmCodeTobeGenerated += Code.LineLabel("LINE","CALL " + $1->name) + Code.twoVarOperation("MOV",temp, "AX"); 

        
        SymbolInfo *current = symboltable->LookupSymbol($1->name); 
        
        if(declareNot(current,$1->name,"factor") || typeCheck(current -> name, current -> getVariableType(), "function")){
            $$ = new SymbolInfo(symbol, "");
        }
        else{   
            listcheck(current->parameterList, $3->argumentList);        
            $$ = new SymbolInfo(symbol, "", current->returnType);
        }
        
        logout<<symbol<<"\n\n";

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);

        Code.argList.clear();        

    }
    | LPAREN expression RPAREN
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: LPAREN expression RPAREN\n\n";
        
        string temp = Code.newTemp();
        string asmCodeTobeGenerated = $2->getAsmCode() + Code.twoVarOperation("MOV","AX", $2->getValueRep()) + Code.twoVarOperation("MOV",temp, "AX");

        string symbol = "("+$2->name+")";		//(expression) -- (exp)
       
        $$ = new SymbolInfo(symbol, $2->getType(), $2->returnType);
        
        logout<<symbol<<"\n\n";

        asmCodeTobeGenerated = Code.Comment(temp + " = " + symbol) + asmCodeTobeGenerated;

        $$->setAsmCode(asmCodeTobeGenerated);
        $$->setValueRep(temp);
    }
    | CONST_INT
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: CONST_INT\n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol, "", "int");
        $$->setValueRep($1->name);

        logout<<symbol<<"\n\n";
        
    }
    | CONST_FLOAT
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: CONST_FLOAT\n\n";
        
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol, "", "float");
        
        logout<<symbol<<"\n\n";
    }
    | variable INCOP
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: variable INCOP\n\n";
        
        string symbol = $1->name+"++";	
        $$ = new SymbolInfo(symbol, "", $1->returnType);

        if($1->name == "array") {
            string asmCodeTobeGenerated, temp;
            temp = Code.newTemp();

            asmCodeTobeGenerated = $1->getAsmCode() + Code.twoVarOperation("MOV","AX", $1->getValueRep() + "[BX]") + Code.oneVarOperation("INC","AX");
            asmCodeTobeGenerated += Code.twoVarOperation("MOV",$1->getValueRep() + "[BX]", "AX") + Code.twoVarOperation("MOV",temp, "AX") + Code.Comment(temp + " = " + symbol) + asmCodeTobeGenerated;

            $$->setAsmCode(asmCodeTobeGenerated);
            $$->setValueRep(temp);
        }       
        else if($1->name!="array") {
            $$->setAsmCode(Code.oneVarOperation("INC",$1->getValueRep()));
            $$->setValueRep($1->getValueRep());
        }

        logout<<symbol<<"\n\n";
    } 
    | variable DECOP
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: variable DECOP\n\n";
        
        string symbol = $1->name+"--";
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        if($1->name == "array") {
            string asmCodeTobeGenerated, temp;
            temp = Code.newTemp();
            asmCodeTobeGenerated = $1->getAsmCode() + Code.twoVarOperation("MOV","AX", $1->getValueRep() + "[BX]") + Code.oneVarOperation("DEC","AX");
            asmCodeTobeGenerated += Code.twoVarOperation("MOV",$1->getValueRep() + "[BX]", "AX") + Code.twoVarOperation("MOV",temp, "AX");
            asmCodeTobeGenerated = Code.Comment(temp + " = " + symbol) + asmCodeTobeGenerated;

            $$->setAsmCode(asmCodeTobeGenerated);
            $$->setValueRep(temp);
        }       
        else if($1->name!="array")
        {

            $$->setAsmCode(Code.oneVarOperation("DEC",$1->getValueRep()));
            $$->setValueRep($1->getValueRep());

        }
        
        logout<<symbol<<"\n\n";

    }
    ;
    
argument_list : arguments
    {
        logout<<"Line "<<yylineno<<": "<<"argument_list : arguments\n\n";
        
        string symbol = $1->name;	
        $$ = new SymbolInfo(symbol);
        $$->argumentList = $1->argumentList;
        $$->setAsmCode($1->getAsmCode());

        logout<<symbol<<"\n\n";
        
    }
    |
    {
        logout<<"Line "<<yylineno<<": "<<"argument_list : \n\n";
        
        string symbol = ""; 
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    ;

arguments : arguments COMMA logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<"arguments : arguments COMMA logic_expression\n\n";
        
        if(voidCheck($3->getReturnType(),"expression"))
            $$->setReturnType("error");
        
        string symbol = $1->name + ", "+$3->name;	
        $$ = new SymbolInfo(symbol, "");
        $$->argumentList = $1->argumentList;
        $$->argumentList.push_back($3->returnType);
        $$->setAsmCode($1->getAsmCode() + $3->getAsmCode());
        Code.argList.push_back($3->getValueRep());

        logout<<symbol<<"\n\n";
    }
    | logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<"arguments : logic_expression\n\n";
        
        if(voidCheck($1->getReturnType(),"expression"))
            $$->setReturnType("error");
            
        string symbol = $1->name;	
        $$ = new SymbolInfo($1->name);
        
        $$->argumentList.push_back($1->returnType);
        $$->setAsmCode($1->getAsmCode());
        Code.argList.push_back($1->getValueRep());
                
        logout<<symbol<<"\n\n";
    }
    | arguments error
    {
        $$ = $1;
        logout<<$$ -> name<<"\n\n";
    }
    ;

%%
int main(int argc,char *argv[])
{
    FILE* input;
        if((input = fopen(argv[1], "r")) == NULL) {
            printf("Cannot Open Input File.\n");
            exit(1);
        }
        if(argc < 3){
            logout.open("logout.txt", ios::out);
            logout.close();
               logout.open("logout.txt", ios::app);
        }
        else {
            logout.open(argv[2], ios::out);
            logout.close();
            logout.open(argv[2], ios::app);
        }
        if(argc < 4){
            error.open("error.txt", ios::out);
            error.close();
            error.open("error.txt", ios::app);
        }
        else {
            error.open(argv[3], ios::out);
            error.close();
            error.open(argv[3], ios::app);
        }
        
        asmCodeGeneration.open("code.asm");
    
    
        yyin = input;
 
        symboltable = new SymbolTable(31);
 
        yyparse(); 

        symboltable -> PrintallScope(logout); 
    
        logout << "Total lines: " << yylineno << endl;
        logout << "Total errors: " << error_count << endl << endl;

        if(error_count) {
        remove("code.asm");
        asmCodeGeneration.open("code.asm");
        }

        fclose(yyin);
        logout.close();
        error.close();
        asmCodeGeneration.close();
    
        return 0;
}
