#include <fstream>
#include <string>
#include<stdio.h>
#include "SymbolInfo.h"
using namespace std;


class ScopeTable
{
    SymbolInfo** head;
    string name="1";
    ScopeTable* parentScope;
    int childpos,totalBuckets;

    unsigned long hash(string &str)
    {
        unsigned long hash = 0;
        int c;

        for(int c:str)
            hash = c + (hash << 6) + (hash << 16) - hash;

        return (hash)%totalBuckets;
    }

    ~ScopeTable()
    {
        SymbolInfo* y=NULL;
        for (int i=0; i<totalBuckets; i++)
        {
            SymbolInfo*x=head[i];
            while(x!=NULL)
            {
                y = x->next;
                delete x;
                x = y;
            }
        }
        delete []head;

    }
public:

    ScopeTable(int bucket)
    {
        this->childpos = 0;
        this->totalBuckets = bucket;
        head = new SymbolInfo*[bucket];
        for (int i = 0; i < bucket; i++)
            head[i] = NULL;
        parentScope = NULL;
    }

    void setParentScope(ScopeTable* parent)
    {
        this->parentScope = parent;
        if(parentScope==NULL)
            name = "1";
        else
            name = parentScope->name + "_" + to_string (++(parentScope->childpos));
    }

    bool Delete(string name)
    {
        int index = hash(name);
        SymbolInfo* current = head[index];
        SymbolInfo* parent = head[index];
        int c = 0;


        if (current == NULL)
        {
            return false;
        }

        if (current->name == name)
        {
            head[index]=current->next;
            delete current;
            return true;
        }

        while (current->name != name && current->next != NULL)
        {
            parent = current;
            current = current->next;
            c++;
        }
        if (current->name == name)
        {
            parent->next = current->next;
            current->next = NULL;
            c++;
            delete current;
            return true;
        }

        return false;
    }

    SymbolInfo* LookUp(string name)
    {
        int index = hash(name);
        SymbolInfo* cur = head[index];
        int s = 0;

        if (cur == NULL)
            return NULL;

        while (cur != NULL)
        {
            if (cur->name == name)
            {
                return cur;
            }
            s++;
            cur = cur->next;
        }

        return NULL;
    }

    bool Insert(string name, string type="", string returnType = "", string variableType = "", vector<string>param = vector<string>(), bool Defined = false)
    {
        int index = hash(name);

        SymbolInfo* newelement = new SymbolInfo(name,type,returnType, variableType, param, Defined);
      
        int c=0;

        if (head[index] == NULL )
        {
            head[index] = newelement;
            return true;
        }

        else if(head[index] != NULL )
        {
            SymbolInfo* cur = head[index];
            while (cur->next != NULL && cur->name!=name)
            {
                cur = cur->next;
                c++;
            }

            if(cur->name!=name)
            {
                c++;
                cur->next = newelement;
     

                return true;
            }
           

        }

        delete newelement;
        return false;
    }
    
     void Print(ofstream &stream)
    {
        stream << "Scopetable# " << name << "\n";
        for(int i = 0; i < totalBuckets; i++)
        {
            SymbolInfo *start = head[i];
            if(start != NULL){
                stream << i << " --> ";
                while(start != NULL)
                {
                    stream << "< " << start -> name << " : " << start -> type << " >";
                    start = start -> next;
                }
                stream << "\n";
            }
           
        }
        stream << "\n";
    }

    friend class SymbolTable;

};


