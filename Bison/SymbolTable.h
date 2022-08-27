#include<bits/stdc++.h>
#include "ScopeTable.h"
using namespace std;


class SymbolTable
{
    ScopeTable* CurrentScope; 

    int totalBuckets;

public:
    SymbolTable(int total)
    {
        this->totalBuckets = total;
        CurrentScope = NULL;
    }
    ~SymbolTable()
    {
        while(CurrentScope!=NULL)
        {
            ScopeTable *tmp = CurrentScope->parentScope;
            delete CurrentScope;
            CurrentScope = tmp;
        }
    }

    bool Enterscope()
    {
        ScopeTable* snew = new ScopeTable(totalBuckets);
        snew->setParentScope(CurrentScope);
        CurrentScope = snew;
      
        return true;
    }
    void ExitScope()
    {
        if(CurrentScope!=NULL)
        {
            ScopeTable *tmp = CurrentScope->parentScope;
            
            delete CurrentScope;
            CurrentScope = tmp;
        }

    }

    bool InsertSymbol(string name, string type="", string returnType = "", string variableType = "", vector<string>param = vector<string>(), bool Defined = false)
    {

        if(CurrentScope==NULL)
            Enterscope();

        if(CurrentScope->Insert(name, type, returnType, variableType, param, Defined))
        {
            return true;
            
            }
            

        return false;
    }
    
 
    bool Remove(string name)
    {
        if(CurrentScope->Delete(name))
        {
            return true;
        }
        else
        {
          
            return false;
        }

    }

    SymbolInfo* LookupSymbol(string name)
    {
        ScopeTable* cur = CurrentScope;
        SymbolInfo* y = NULL;
        while(cur!=NULL)
        {
            SymbolInfo* x = cur->LookUp(name);
            y = x;
            if(x!=NULL)
            {
                return x;
            }
            cur = cur->parentScope;
        }
       
        return NULL;
    }
    SymbolInfo* LookupSymbolInCurrent(string name)
    {
        return (CurrentScope == NULL ? NULL : CurrentScope -> LookUp(name));
    }
    
    void PrintCurrentScope()
    {
        if(CurrentScope!=NULL)
        {
            //CurrentScope->Print();
        }
    }

    void PrintallScope(ofstream &stream)
    {
        ScopeTable* cur = CurrentScope;
        while(cur!=NULL)
        {
         
            cur->Print(stream);
            cur = cur->parentScope;
            
        }
    }


};

