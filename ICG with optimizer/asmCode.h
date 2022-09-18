#include<bits/stdc++.h>
using namespace std;
class asmCode{
public :

    string mainCode;
    int tempVarCount = 0 , labelCount=0;

    struct FunctionScope{
        string name;
        string code;
        int paramSize;

        FunctionScope()
        {

        }

        FunctionScope(string n,string c,int paramNum)
        {
            this->name = n;
            this->code = c;
            this-> paramSize = paramNum;
        }

    };

    vector<FunctionScope> FuncList;
    vector<string> varList , tempList , argList;

    string newLabel()
    {
        labelCount++;
        string str = "Label" + to_string(labelCount-1);
        return str;
    }

    string newTemp()
    {
        string str = "Temp" + to_string(tempVarCount);
        tempVarCount++;
        tempList.push_back(str  + " DW ? ");
        return str;
    }

    string varNameing(string var)
    {
        return var +"1";
    }

    void insertFunctionToList(string name, string code, int paramSize) {

        FuncList.push_back(FunctionScope(name, code, paramSize));

    }

    string Comment(string str) {

        string comment = "; " + str + "\n";

        return comment; 
    }
    string LineLabel(string op, string str, string comment = "")
    {
        if(op=="LINE")
        {
            if(comment.size()) 
                str += "\t\t\t; " + comment;

            str += "\n";
            
            return str;
        }
        else if(op=="Label")
            {
                str += ":\t\t\t\t" + Comment(comment);
                return str; 
            }

    }

    string CmpJump(string op, string src1, string src2, string comment = "") {

        string str = ""; 
        if(op=="Cmp")
        {
            str = "CMP " + src1 + ", " + src2 + "\t\t\t" + Comment(comment);
            return str;
        }

        else if(op=="Jump")
        {
            str = src1 + " " + src2 + "\t\t\t\t" + Comment(comment);
        }

        return str;
    }

    string oneVarOperation(string op,string var)
    {
        if (op== "PUSH")
            return "PUSH " + var + "\t\t\t; STACK <- " + var + "\n";
        else if (op== "POP")
            return "POP "  + var + "\t\t\t; STACK -> " + var + "\n";
        else if(op=="INC")
            return "INC " + var + "\t\t\t\t; " + var + "++\n";
        else if(op=="DEC")
            return "DEC " + var + "\t\t\t\t; " + var + "--\n";
        else if(op=="NEG")
            return "NEG " + var + "\t\t\t; " + var + " = -1*" + var + "\n";
        return "";
    }

    //Operation on two var : MOV, ADD ,SUB
    string twoVarOperation(string op,string src,string dest)
    {
        if(op=="MOV")
            return "MOV " + src + ", " + dest + "\t\t\t; " + src + " = " + dest + "\n";
        else if(op=="ADD")
             return "ADD " + src + ", " + dest + "\t\t\t; " + src + " = " + src + " + " + src + "\n";
        else if(op=="SUB")
             return "Sub " + src + ", " + dest + "\t\t\t; " + dest + " = " + dest + " - " + src + "\n";

        return "";
    }

    //MUL, DIV, LOGICOR, LOGICAND
    string MULDIVLOGIC(string op,string z, string x, string y, bool isDiv="") {

        string str = "" ;

        if(op=="MUL")
        {
            str = "XOR DX, DX\t\t\t; CLEAR OUT DX\nMOV AX, " + x + "\t\t\t; DX:AX = 00:" + x + "\nIMUL " + y + "\t\t\t; (DX:AX) <- AX*" + y + " = " + x + "*" + y + "\n";
            str += "MOV " + z + ", AX\t\t\t; PRODUCT IN " + z + " -> " + z + " = " + x + "*" + y + "\n";
            return str;
        }

        else if(op=="DIV")
        {
            str = "XOR DX, DX\t\t\t; CLEAR OUT DX\nMOV AX, " + x + "\t\t\t; DX:AX = 00:" + x + "\nIDIV " + y + "\t\t\t; (DX:AX) / " + y + " -> QUOTIENT IN AX, REMAINDER IN DX\n";
            if(isDiv)
                str += "MOV " + z + ", AX\t\t\t; QUOTIENT IN " + z + " -> " + z + " = " + x + "/" + y + "\n";
            else str += "MOV " + z + ", DX\t\t\t; REMAINDER IN " + z + " -> " + z + " = " + x + "%" + y + "\n";
            return str;
        }

        else if(op=="LOGICOR")
        {
            string expression = x + " || " + y;
            str = Comment(z + " <- " + expression);
            string label = newLabel();
            str += LineLabel("LINE","MOV " + z + ", 1", "SUPPOSE" + expression + " IS TRUE") + CmpJump("Cmp",x, "0", "CHECK IF " + x + " IS FALSE");
            str += CmpJump("Jump","JNE", label) + CmpJump("Cmp", y, "0", "CHECK IF OPERAND" + x + " IS FALSE TOO") + CmpJump("Jump","JNE", label); 
            str += LineLabel("LINE","MOV " + z + ", 0", expression + " IS FALSE") + LineLabel("Label",label) + "\n";
            return str;
        }

        else if(op=="LOGICAND")
        {
            string expression = x + " && " + y;
            string label = newLabel();
            str = Comment(z + " <- " + expression) + LineLabel("LINE","MOV " + z + ", 1", "ASSUMING " + expression + " TO BE FALSE") + CmpJump("Cmp",x, "0", "CHECK IF " + x + " TRUE");//Cmp
            str += CmpJump("Jump","JE", label)+ CmpJump("Cmp", y, "0", "CHECK IF " + x + " IS ALSO TRUE") + CmpJump("Jump","JE", label); //use jmp
            str += LineLabel("LINE","MOV " + z + ", 1", expression + " IS TRUE") + LineLabel("Label",label) + "\n";//using Label

        }

        return str;

    }

    string returnDelete(string str, string returnLabel) {
        int start = 0;
        int end = -1;
        while(true) {
            start = str.find("RETURN", 0);
            if(start == string::npos) 
                break;
            end = str.find("\n", start);

            string returnValue;
            stringstream ss(str.substr(start, end-start+1));
            ss >> returnValue >> returnValue;
            int position = str.erase(str.begin()+start, str.begin()+end+1) - str.begin();
            string tobeInserted = twoVarOperation("MOV","AX", returnValue) + CmpJump("Jump","JMP", returnLabel, "return");
            str.insert(position, tobeInserted);
        }
        return str;
    }

    string asmProcedure(FunctionScope f) {
        string returnLabel = newLabel();
        string asmStr = LineLabel("LINE",";-----------------------------------------") +  LineLabel("LINE",f.name + " PROC") + LineLabel("LINE","PUSH BP");
        asmStr += LineLabel("LINE","MOV BP, SP") + returnDelete(f.code, returnLabel) + LineLabel("Label",returnLabel) + LineLabel("LINE","POP BP");
        asmStr += LineLabel("LINE","RET " + to_string(f.paramSize*2)) + LineLabel("LINE","ENDP " + f.name) + LineLabel("LINE",";-----------------------------------------;");

        return asmStr;
    }

};
