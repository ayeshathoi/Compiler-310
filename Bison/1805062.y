%{
#include<bits/stdc++.h>
using namespace std;
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*

int yyparse(void);
int yylex(void);

extern FILE *yyin;
ofstream logout;
ofstream error;
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


void yyerror(string s)
{
	logout << "Error at line " << yylineno <<": " <<s <<"\n\n";
	error  << "Error at line " << yylineno <<": " <<s <<"\n\n";
	error_count++;
}

bool typeCheck(string name, string type, string actual)
{
    //cerr << yylineno << ": " << name << ' ' << type << ' ' << actual << endl;
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

void functionProcess(vector<SymbolInfo*> declist, string ret)
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
	}
	;

program : program unit 
	{
		logout<<"Line "<<yylineno<<": "<<" program : program unit\n\n";
		
		string symbol = $1->name;                   // program
        symbol += "\n" + $2->name;                   // unit
		$$ = new SymbolInfo(symbol);
		
		logout<<symbol<<"\n\n";
	}
	| unit
	{
		logout<<"Line "<<yylineno<<": "<<" program : unit\n\n";
		
		string symbol = $1->name;                  //unit
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
        
        string symbol = $1->name;		// var_declaration
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    | func_declaration
    {
        logout<<"Line "<<yylineno<<": "<<" unit : func_declaration\n\n";
        
        string symbol = $1->name;		// func_declaration
        $$ = new SymbolInfo($1->name);
        
        logout<<symbol<<"\n\n";
    }
    | func_definition
    {	
         logout<<"Line "<<yylineno<<": "<<" unit : func_definition\n\n";
         
         string symbol = $1->name;		// func_definition
         $$ = new SymbolInfo(symbol);
         
        logout<<symbol<<"\n\n";
    }
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
        
        
        string symbol = $1->name;                    // type_specifier
        symbol += " " + $2->name;                   // ID
        symbol += "(" + $4->name  + ");";          // (parameter_list);
                
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
        Param_List.clear();
        
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
        
        string symbol = $1->name;                     // type_specifier
        symbol += " " + $2->name;                  // ID 
        symbol += "();";                          // ( no parameter );
        
        $$ = new SymbolInfo(symbol);
    
        logout<<symbol<<"\n\n";
        
        
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
          
        string symbol = $1->name;                  // type_specifier 
        symbol += " " + $2->name;                // ID
        symbol += "(" + $4->name + ")";          // (parameter_list)
        symbol += $7->name;                      // compound_statement
        $$ = new SymbolInfo(symbol);
        logout<<symbol<<"\n\n";
        
        retType = NULL; 
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
        
        string symbol = $1->name;                   // type_specifier 
        symbol += " " + $2->name;                  // ID
        symbol += "()";                           // ( no parameter )
        symbol += $6->name;                      // compound_statement
                
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
        
        retType = NULL;
    }
    ;	

parameter_list  : parameter_list COMMA type_specifier ID
    {
        logout<<"Line "<<yylineno<<": "<<" parameter_list : parameter_list COMMA type_specifier ID\n\n";\
        
        Param_List.push_back($3->name);
        
        string symbol = $1->name;                  // parameter_list
        symbol += "," + $3->name;                  // ,type_specifier
        symbol += " " + $4->name;                  // ID
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
        
        string symbol = $1->name;                  // parameter_list
        symbol += "," + $3->name;                  // ,type_specifier
                
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
        
        string symbol = $1->name ;   // type_specifier
        symbol += " " + $2->name;    //	ID
        
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
        
        string symbol = $1->name ;   // type_specifier
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
            
        funcName = "";
        Param_List.clear();
        Params_List.clear();
        
    } statements RCURL
    {
        string symbol = "{\n"+$3->name+"\n}";	//{statements}
        $$ = new SymbolInfo(symbol, "");
        
        logout<<symbol<<"\n\n"; 
        
        symboltable->PrintallScope(logout); 
        symboltable->ExitScope();   
    }
    | LCURL
    {
        symboltable->Enterscope();
        
        paramfuncProcess(Params_List, funcName);

        funcName = "";
        Param_List.clear();
        Params_List.clear();
        
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
                
        string symbol = $1->name;                // type_specifier
        symbol += " " + $2->name + ";";          // declaration_list;
        $$ = new SymbolInfo(symbol);
        logout<<symbol<<"\n\n";
        
        functionProcess(Dec_List, $1 -> name);
        
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
            
        string symbol = $1->name; 		//declaration_list
        symbol += "," + $3->name;		//ID
        
        $$ = new SymbolInfo(symbol);
                    
        $3->variableType = "variable";
        Dec_List.push_back($3);
            
        logout<<symbol<<"\n\n";
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        
        logout<<"Line "<<yylineno<<": "<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n";
        
        string symbol = $1->name + ",";                   // declaration_list, 
        symbol += $3->name;                               // ID
        symbol += "[" + $5->name + "]";       // [CONST_INT]
                
        $$ = new SymbolInfo(symbol);
                
        $3->variableType = "array";
        Dec_List.push_back($3);
        
        
        logout<<symbol<<"\n\n";
    }
    | ID
    {	
        logout<<"Line "<<yylineno<<": "<<" declaration_list : ID\n\n";
            
        string symbol = $1->name;
        $$ = new SymbolInfo(symbol);
            
        $1->variableType = "variable";
        Dec_List.push_back($1);
            
        logout<<symbol<<"\n\n";
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        logout<<"Line "<<yylineno<<": "<<" declaration_list :  ID LTHIRD CONST_INT RTHIRD\n\n";
        
        string symbol = $1->name; 		//ID 
        symbol += "[" + $3->name + "]";		//[CONST_INT]
        $$ = new SymbolInfo(symbol);
            
        $1->variableType = "array";	
        
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
			
        string symbol = $1->name; 		//statement
        $$ = new SymbolInfo($1->name);
        
        logout<<symbol<<"\n\n";
    }
    | statements statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : statements statement\n\n";
            
        string symbol = $1->name;		// statements
        symbol += "\n"+$2->name;		//statement
        $$ = new SymbolInfo(symbol);
			
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
        
        string symbol = $1->name; 		//var_declaration
        $$ = new SymbolInfo(symbol);
    
        logout<<symbol<<"\n\n";
    }
    | expression_statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : expression_statement\n\n";
            
        string symbol = $1->name; 		//expression_statement
        $$ = new SymbolInfo(symbol);
        logout<<symbol<<"\n\n";
    }
    | compound_statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : compound_statement\n\n";
			
        string symbol = $1->name; 		//compound_statement
        $$ = new SymbolInfo(symbol);
			
        logout<<symbol<<"\n\n";
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
	    		
        string symbol = "for(" + $3->name;                         // for(expression_statement
        symbol += $4->name;                                        // expression_statement
        symbol += $5->name + ")";                                  // expression)            
        symbol += $7->name;                                        // statement
    
        $$ = new SymbolInfo(symbol);
			
        logout<<symbol<<"\n\n";
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE 
    {
        logout<<"Line "<<yylineno<<": "<<" statement : IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE\n\n";
	    		
        string symbol = "if(" ;                         // if(
        symbol += $3->name + ")\n";                     // expression)\n            
        symbol += $5->name;  				//statement
        
        $$ = new SymbolInfo(symbol);
			
        logout<<symbol<<"\n\n";
			
        voidCheck($3->getReturnType(),"if"); 
			
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        logout<<"Line "<<yylineno<<": "<<" statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
        
        string symbol = "if(" ;                         // if(
        symbol += $3->name + ")";                     // expression)\n            
        symbol += $5->name;  				//statement
        symbol +=  "\nelse\n";				//else
        symbol += $7->name;				//statement
        
        $$ = new SymbolInfo(symbol);
			
        voidCheck($3->getReturnType(),"if");
			
        logout<<symbol<<"\n\n";
    }
    | WHILE LPAREN expression RPAREN statement
    {
        $$ = new SymbolInfo("while("+$3->name+")\n"+$5->name);
        logout<<"Line "<<yylineno<<": "<<" statement : WHILE LPAREN expression RPAREN statement\n\n";
			
        string symbol = "while(" ;                     // while(
        symbol += $3->name + ")";                     // expression)\n            
        symbol += $5->name;  			     //statement
             
        $$ = new SymbolInfo(symbol);
			
        voidCheck($3->getReturnType(),"if");
			
        logout<<symbol<<"\n\n";
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
		
        logout<<"Line "<<yylineno<<": "<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
			
        string symbol = "printf(" ;                       //println(
        symbol += $3->name +");";                         //ID);          
        $$ = new SymbolInfo(symbol);
        
        SymbolInfo *current = symboltable->LookupSymbol($3->name);
		if(!declareNot(current,$3->name,"statement"))
            typeCheck(current -> name, current->variableType, "variable");	
        
        logout<<symbol<<"\n\n";
			
    }
    | RETURN expression SEMICOLON
    {
        logout<<"Line "<<yylineno<<": "<<" statement : RETURN expression SEMICOLON\n\n";
        
        string symbol = "return " ;                       //return 
        symbol += $2->name+";";				  //expression;
        $$ = new SymbolInfo(symbol);
        
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
            
        string symbol = ";" ;   		//;
        
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }		
    | expression SEMICOLON 
    {
        logout<<"Line "<<yylineno<<": "<<"expression_statement : expression SEMICOLON \n\n";
        
        string symbol = $1->name+";" ;   //expression;
        
        $$ = new SymbolInfo(symbol);
        $$ -> setReturnType($1 -> getReturnType()); 
        
        logout<<symbol<<"\n\n";
    }		
    ;

variable: ID
    {
        logout<<"Line "<<yylineno<<": "<<"variable : ID \n\n";
        
        SymbolInfo *current = symboltable->LookupSymbol($1->name);	//ID declaration check
        
        string symbol = $1->name;		//ID 
        if(declareNot(current,$1->name,"variable") || typeCheck(current -> name, current->variableType, "variable"))
        {	
            $$ = new SymbolInfo(symbol);
        }
        else 
            $$ = new SymbolInfo(symbol, "", current->returnType, current -> variableType);
        logout<<symbol<<"\n\n";

    }
    | ID LTHIRD expression RTHIRD
    {
    
        logout<<"Line "<<yylineno<<": "<<"variable : ID LTHIRD expression RTHIRD \n\n";
        
        string symbol = $1->name;		//ID 
        symbol += "["+$3->name+"]";		//[expression]
        SymbolInfo *current = symboltable->LookupSymbol($1->name);

        //typecheck to array kina check kortese na
        
        if(declareNot(current,$1->name,"array")||typeCheck(current -> name, current->variableType, "array"))
            $$ = new SymbolInfo(symbol, "");
        else
        {
            if($3->returnType != "int") 
                yyerror("Array index not integer");
            $$ = new SymbolInfo(symbol, "", current->returnType, current->variableType);
        }
        
        logout<<symbol<<"\n\n";
    }
	 ;	 
expression : logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<" expression : logic_expression \n\n";
        
        string symbol = $1->name;		//logic_expression
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
    }
    | variable ASSIGNOP logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<" expression : variable ASSIGNOP logic_expression \n\n";
        //cerr << yylineno << ": " << $1 -> variableType << endl;
        if(voidCheck($3->getReturnType(),"expression") || $1 -> returnType == "float" && $3->returnType == "int")
            ;
        else if($1 -> variableType == "variable" && $1->returnType != $3->returnType) 
        {
            yyerror("Type Mismatch");
        }
			
        string symbol = $1->name;		//variable
        symbol += " = " + $3 -> name;		//= logic_expression
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
   }
   ;
		
			
logic_expression : rel_expression
    {
        logout<<"Line "<<yylineno<<": "<<" logic_expression : rel_expression \n\n";
        
        string symbol = $1->name;		//rel_expression 
        $$ = new SymbolInfo($1->name, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
    }	
    | rel_expression LOGICOP rel_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" logic_expression : rel_expression LOGICOP rel_expression \n\n";
        
        string symbol = $1->name;		//rel_expression 
        symbol += " "+$2->name; 		//LogicOp &&,||
        symbol += " "+$3->name;			//rel_expression -- x+y<3 && z>5
        
        bool checkone = voidCheck($1->getReturnType(),"expression");
        
        bool checktwo = false;
                
        if(!checkone)
        {
            checktwo = voidCheck($3->getReturnType(),"expression");
        }
        
        if(checkone || checktwo) $$ = new SymbolInfo(symbol, "");
        
        else
        {
            $$ = new SymbolInfo(symbol, "", "int");
        }

        
        logout<<symbol<<"\n\n";
    }
    ;
		
			
rel_expression	: simple_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" rel_expression	: simple_expression  \n\n";
        
        string symbol = $1->name;		//simple_expression 
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
        
    }
    | simple_expression RELOP simple_expression
    {
        logout<<"Line "<<yylineno<<": "<<" rel_expression	: simple_expression RELOP simple_expression \n\n";
        
        string symbol = $1->name;		//simple_expression
        symbol += " "+$2->name; 		//RELOP <,<=,>,>=,==,!=
        symbol += " "+$3->name;			//simple_expression -- x+y <= 5-z*4
        
        bool checkone = voidCheck($1->getReturnType(),"expression");
        
        bool checktwo = false;
                
        if(!checkone)
        {
            checktwo = voidCheck($3->getReturnType(),"expression");
        }
        
        if(checkone || checktwo) $$ = new SymbolInfo(symbol);
        
        else
        {
            $$ = new SymbolInfo(symbol, "", "int");
        }
        
        logout<<symbol<<"\n\n";
    }
    ;
				
simple_expression :term
    {
        logout<<"Line "<<yylineno<<": "<<" simple_expression : term \n\n";
        
        string symbol = $1->name;		//term (5/x)
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
    }
    | simple_expression ADDOP term
    {
            
        logout<<"Line "<<yylineno<<": "<<" simple_expression : simple_expression ADDOP term \n\n";
        
        string symbol = $1->name;		//simple_expression -- x+3*y-(5/x)
        symbol += " "+$2->name; 		//ADDOP +,-
        symbol += " "+$3->name;			//term
        
        bool checkone = voidCheck($1->getReturnType(),"expression");

        bool checktwo = false;
        
        if(!checkone)
        {
            checktwo = voidCheck($3->getReturnType(),"expression");
        }

        if(checkone || checktwo) 
            $$ = new SymbolInfo(symbol," ","void");
        else if($1->returnType == "float" || $3->returnType == "float") 
            $$ = new SymbolInfo(symbol, "", "float");
        else
            $$ = new SymbolInfo(symbol, "","int");
        
        logout<<symbol<<"\n\n";
    } 
    ;
					
term :	unary_expression
	{
		logout<<"Line "<<yylineno<<": "<<" term :	unary_expression \n\n";
		
		string symbol = $1->name;		//unary_expression
		$$ = new SymbolInfo($1->name, "", $1->returnType);
		
		logout<<symbol<<"\n\n";
	}
    |  term MULOP unary_expression
	{
		
		logout<<"Line "<<yylineno<<": "<<" term : term MULOP unary_expression\n\n";
		
		string symbol = $1->name;		//term
		symbol += " "+$2->name; 		//MULOP *,/,%
		symbol += " "+$3->name;			//unary_expression -- 3.14 * -arr[exp]
		 				
		$$ = new SymbolInfo(symbol,"", "int"); 
		logout<<symbol<<"\n\n";
		bool check = true;
		string str = $3->name;
		
		for(int i=0;i<str.size();i++)
		{
			if(str[i]!='0')
				check = false;
		}
			
		if(voidCheck($1->getReturnType(),"expression") || voidCheck($3->getReturnType(),"expression")) 
			;
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
	}
    ;

unary_expression : ADDOP unary_expression  
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : ADDOP unary_expression\n\n";
        
        voidCheck($2->getType(),"expression");
        
        string symbol = $1->name;		//Addop +,-
        symbol += " "+$2->name; 		//unary_expression
        $$ = new SymbolInfo(symbol, $2->getType(), $2 -> returnType);
        
        logout<<symbol<<"\n\n";
        
    }
    | NOT unary_expression 
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : NOT unary_expression\n\n";
        
        voidCheck($2->getType(),"expression");
        
        string symbol = "!";		//Not !
        symbol += $2->name; 		//unary_expression 
        
        $$ = new SymbolInfo(symbol , $2->getType(), $2 -> returnType); 
        
        logout<<symbol<<"\n\n";
        
    }
    | factor
    {
        logout<<"Line "<<yylineno<<": "<<" unary_expression : factor\n\n";
        
        string symbol = $1->name ;		//factor
        $$ = new SymbolInfo(symbol , $1->getType(), $1 -> returnType);
        
        logout<<symbol<<"\n\n";
    }
    ;

factor : variable
    {
        //  smallest block of an expression
        
        logout<<"Line "<<yylineno<<": "<<"factor	: variable\n\n";
        
        string symbol = $1->name ;		//variable -- x, arr[exp]
        $$ = new SymbolInfo(symbol, $1->getType(), $1->returnType);
        
        logout<<symbol<<"\n\n";
    }
	| ID LPAREN argument_list RPAREN
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: ID LPAREN argument_list RPAREN\n\n";
        
        string symbol = $1->name+"(";		//ID(
        symbol += $3->name+")";			//argument_list) --foo(arg_list)
        
        SymbolInfo *current = symboltable->LookupSymbol($1->name); 
        
        if(declareNot(current,$1->name,"factor") || typeCheck(current -> name, current -> getVariableType(), "function")){
            $$ = new SymbolInfo(symbol, "");
        }
        else{   
            listcheck(current->parameterList, $3->argumentList);        
            $$ = new SymbolInfo(symbol, "", current->returnType);
        }
        
        logout<<symbol<<"\n\n";
    }
	| LPAREN expression RPAREN
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: LPAREN expression RPAREN\n\n";
        
        string symbol = "("+$2->name+")";		//(expression) -- (exp)
       
        $$ = new SymbolInfo(symbol, $2->getType(), $2->returnType);
        
        logout<<symbol<<"\n\n";
    }
	| CONST_INT
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: CONST_INT\n\n";
        
        string symbol = $1->name;		//CONST_INT
        $$ = new SymbolInfo(symbol, "", "int");
        
        logout<<symbol<<"\n\n";
    }
	| CONST_FLOAT
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: CONST_FLOAT\n\n";
        
        string symbol = $1->name;		//CONST_FLOAT
        $$ = new SymbolInfo(symbol, "", "float");
        
        logout<<symbol<<"\n\n";
    }
	| variable INCOP
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: variable INCOP\n\n";
        
        string symbol = $1->name+"++";		//variable++ : x++, arr[exp]++  
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
    } 
	| variable DECOP
    {
        logout<<"Line "<<yylineno<<": "<<"factor	: variable DECOP\n\n";
        
        string symbol = $1->name+"--";		//variable--   
        $$ = new SymbolInfo(symbol, "", $1->returnType);
        
        logout<<symbol<<"\n\n";
    }
	;
	
argument_list : arguments
    {
        logout<<"Line "<<yylineno<<": "<<"argument_list : arguments\n\n";
        
        string symbol = $1->name;		//arguments : 5, x+y
        $$ = new SymbolInfo(symbol);
        $$->argumentList = $1->argumentList;
        
        logout<<symbol<<"\n\n";
    }
    |
    {
        logout<<"Line "<<yylineno<<": "<<"argument_list : \n\n";
        
        string symbol = ""; 		//empty string
        $$ = new SymbolInfo(symbol);
        
        logout<<symbol<<"\n\n";
    }
    ;

arguments : arguments COMMA logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<"arguments : arguments COMMA logic_expression\n\n";
        
        voidCheck($3->getType(),"expression");
        
        string symbol = $1->name;		//arguments
        symbol += ", "+$3->name;		//,logic_expression
        
        $$ = new SymbolInfo(symbol, "");
        
        $$->argumentList = $1->argumentList;
        $$->argumentList.push_back($3->returnType);
        
        logout<<symbol<<"\n\n";
    }
    | logic_expression
    {
        logout<<"Line "<<yylineno<<": "<<"arguments : logic_expression\n\n";
        
        voidCheck($1->getType(),"expression");
            
        string symbol = $1->name;		//logic_expression	
        $$ = new SymbolInfo($1->name);
        
        $$->argumentList.push_back($1->returnType);
        
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
    
    
    yyin = input;
 
    symboltable = new SymbolTable(31);
 
    yyparse(); // processing starts

    symboltable -> PrintallScope(logout); 
    
    logout << "Total lines: " << yylineno << endl;
    logout << "Total errors: " << error_count << endl << endl;

    fclose(yyin);
    logout.close();
    error.close();
    
    return 0;
}

