
vector<string> lines;
string op = ";/t/t/t/t piphole optimized";

vector<string> stringTokenize(string s, string delim){
    string token;
    vector<string> ret;
    for(auto x : s){
        if(delim.find(x) != string::npos){
            if(!token.empty())ret.push_back(token);
            token.clear();
            continue;
        }
        token += x;
    }
    
    if(!token.empty())ret.push_back(token);
    return ret;
}


void removeLine(int i){
    lines[i] = op + lines[i];
}

bool isEmptyOrComment(int t){
    string s = lines[t];
    int i = 0;
    while(i < s.size() && isspace(s[i]))i++;
    return i < s.size() && s[i] == ';' || i == s.size();
}


void optimizer(string asmcode, string optcode){
    ifstream fin(asmcode);
    ofstream fout(optcode);
    string s;
    while(!fin.eof()){
        getline(fin, s);
        lines.push_back(s);
    }
    
    int n = lines.size();
    
    int codeStart = 0;
    string delim = " \n,";
    while(codeStart < n){
        if(lines[codeStart].empty() || lines[codeStart][0] != '.'){
            codeStart++;
            continue;
        }
        vector<string> s = stringTokenize(lines[codeStart], delim);
        if(s[0] == ".CODE")break;
        codeStart++;
    }
    
    //got codeStart
    
    
    //REMOVE ADD  , 0 SUB , 0 
    for(int i = codeStart + 1; i < n; i++){
        if(isEmptyOrComment(i))continue;
         vector<string> s = stringTokenize(lines[i], delim);
        
        if(s[0] == "ADD" || s[0] == "SUB"){
            if(s[2] == "0"){
                removeLine(i);
            }
        }
        
    }
    
    
    
    //MOV AX, BX
    //MOV BX, AX
    
    int l = codeStart + 1;
    while(l < n && isEmptyOrComment(l))l++;
    
    vector<string> lastTokens;
    if(l < n)lastTokens = stringTokenize(lines[l], delim);
    
    for(int i = l + 1; i < n; i++){
        if(isEmptyOrComment(i))continue;
        vector<string> s = stringTokenize(lines[i], delim);
        if(lastTokens[0] != "MOV" || s[0] != "MOV"){
            l = i;
            lastTokens = s;
            continue;
        }
        
        
        if(lastTokens[1] == s[1]){
            if(lastTokens[2] == s[2]){
                removeLine(i);
                continue;
            }
        }else if(lastTokens[1] == s[2]){
            if(lastTokens[2] == s[1]){
                removeLine(i);
                continue;
                
            }
        }
        
        l = i;
        lastTokens = s;
    }
    
    //PUSH BX
    //POP BX
    l = codeStart + 1;
    while(l < n && isEmptyOrComment(l))l++;
    
    if(l < n)lastTokens = stringTokenize(lines[l], delim);
    
    for(int i = l + 1; i < n; i++){
        if(isEmptyOrComment(i))continue;
        vector<string> s = stringTokenize(lines[i], delim);
        
        if(s[0] != "POP" || lastTokens[0] != "PUSH"){
            l = i;
            lastTokens = s;
            continue;
        }
        
        
        if(lastTokens[1] == s[1]){
            removeLine(l);
            removeLine(i);
            l = i + 1;
            while(l < n && isEmptyOrComment(l))l++;
            i = l;
            
            if(l < n)lastTokens = stringTokenize(lines[l], delim);
            
            continue;
        }
        
        l = i;
        lastTokens = s;
        
    }
    
    
    
    for(auto x : lines)fout << x << "\n";
    
    
}
