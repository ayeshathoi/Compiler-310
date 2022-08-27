#include<bits/stdc++.h>
using namespace std;

class SymbolInfo
{

public:
    string name,type,variableType,returnType;
    int arraySize=-1;
    vector<string> parameterList;
    SymbolInfo* next;
    vector<string> argumentList;
    string asmCode;
    string valueRep; 
    bool defined;
    SymbolInfo()
    {
        next = NULL;
        this->defined = false;
    }

    SymbolInfo(string name)
    {
    	this->name = name;
        next = NULL;
        this->defined = false;
    }

    SymbolInfo(string name, string type)
    {
    	this->name = name;
    	this->type = type;
        next = NULL;
        this->defined = false;
    }

    SymbolInfo(string name, string type,string returnType)
    {
    	this->name = name;
        this->type = type;
        this->returnType = returnType;
        next = NULL;
        this->defined = false;
    }

    SymbolInfo(string name, string type,string returnType,string variableType)
    {
        this->name = name;
        this->type = type;
        this->returnType = returnType;
        this->variableType = variableType;
        this->defined = false;
        next = NULL;
    }

    SymbolInfo(string name, string type,string returnType,string variableType,vector<string>parameter)
    {
        this->name = name;
        this->type = type;
        this->returnType = returnType;
        this->variableType = variableType;
        this->parameterList = parameter;
        this->defined = false;
        next = NULL;
    }

    SymbolInfo(string name, string type,string returnType,string variableType,vector<string>parameter,bool def)
    {
        this->name = name;
        this->type = type;
        this->returnType = returnType;
        this->variableType = variableType;
        this->parameterList = parameter;
        this->defined = def;
        next = NULL;
    }

    ~SymbolInfo()
    {

    }

     void setName(string name){
        this->name = name;
    }

    string getName(){
        return this->name;
    }

    void setType(string type){
        this->type = type;
    }


    string getType(){
        return this->type;
    }

    void setArraySize(int asize)
    {
        this->arraySize = asize;
    }

    int getArraySize()
    {
        return this->arraySize;
    }
    void setVariableType(string variable_type){
        this->variableType = variable_type;
    }


    string getVariableType(){
        return this->variableType;
    }

    void setReturnType(string returnType){
        this->returnType = returnType;
    }


    string getReturnType(){
        return this->returnType;
    }

    void setDefined(bool defined){
        this->defined = defined;
    }

    bool getDefined(){
        return this->defined;
    }



    void setNext(SymbolInfo* nextsymbol){
        this->next = nextsymbol;
    }

    SymbolInfo* getNext(){
        return this->next;
    }
    
    void setValueRep(string valueRep) {
        this->valueRep = valueRep;
    }
    string getValueRep() {
        return this->valueRep;
    }

    void setAsmCode(string asmCode) {
        this->asmCode = asmCode;
    }
    string getAsmCode() {
        return this->asmCode;
    }

    string intToStr(int x) {
        string ret = "";
        while(x) {
            ret += (char)(x%10 + '0');
            x /= 10;
        }
        reverse(ret.begin(), ret.end());
        return ret;
    }

    friend class ScopeTable;
};
