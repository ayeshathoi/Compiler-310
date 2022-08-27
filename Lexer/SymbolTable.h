#include <fstream>
#include <string>
using namespace std;
class SymbolInfo
{
    string identifier, type;
    SymbolInfo* next;

public:
    SymbolInfo()
    {
        next = NULL;
    }

    SymbolInfo(string key, string type)
    {
        this->identifier = key;
        this->type = type;
        next = NULL;
    }

    ~SymbolInfo()
    {

    }

    friend class ScopeTable;
};

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
            name = parentScope->name + "." + to_string (++(parentScope->childpos));
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

        if (current->identifier == name)
        {
            head[index]=current->next;
            delete current;
            return true;
        }

        while (current->identifier != name && current->next != NULL)
        {
            parent = current;
            current = current->next;
            c++;
        }
        if (current->identifier == name)
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
            if (cur->identifier == name)
            {
                return cur;
            }
            s++;
            cur = cur->next;
        }

        return NULL;
    }

    bool Insert(string name,string Type)
    {
        int index = hash(name);

        SymbolInfo* newelement = new SymbolInfo(name,Type);
        int c=0;

        if (head[index] == NULL )
        {
            head[index] = newelement;
            return true;
        }

        else if(head[index] != NULL )
        {
            SymbolInfo* cur = head[index];
            while (cur->next != NULL && cur->identifier!=name)
            {
                cur = cur->next;
                c++;
            }

            if(cur->identifier!=name)
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
                    stream << "< " << start -> identifier << " : " << start -> type << " >";
                    start = start -> next;
                }
                stream << "\n";
            }
           
        }
        stream << "\n";
    }

    friend class SymbolTable;

};

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

    bool InsertSymbol(string name,string type)
    {

        if(CurrentScope==NULL)
            Enterscope();

        if(CurrentScope->Insert(name,type))
            return true;

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

