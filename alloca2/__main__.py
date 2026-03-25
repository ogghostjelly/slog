# Reads the template file from `index.template.html` and outputs to `index.html`
# applys syntax highlighting to <code> blocks.

import bs4, random

class Tokenizer:
    def __init__(self, lang: str, inp: str) -> None:
        self.input = inp
        self.lang = lang
    def collect(self) -> list:
        toks = []
        while tok := self.next():
            toks.append(tok)
        return toks
    def next(self) -> str:
        if self.peek() == None:
            return None
        space = self.take_while(lambda ch: ch.isspace())
        if len(space) != 0:
            return { "value": space, "type": None }
        
        if self.lang == "c":
            return self.next_c()
        if self.lang == "nasm" or self.lang == "simple":
            return self.next_nasm()
        if self.lang == "rainbow":
            return self.next_rainbow()
        
        tok = { "value": self.input, "type": None }
        self.input = ""
        return tok
    def next_rainbow(self) -> str:
        return { "value": self.pop(), "type": random.choice(["comment", "number", "symbol", "string", "type", "operand"]) }
    def next_nasm(self) -> str:
        if self.input.startswith(";"):
            return { "value": self.take_while(lambda ch: ch != '\n'), "type": 'comment' }
        if self.peek().isnumeric():
            return { "value": self.take_while(isvalid), "type": 'number' }
        if self.peek().isalpha() or self.peek() in "_.@":
            return { "value": self.take_while(isvalid), "type": 'symbol' }
        return { "value": self.pop(), "type": 'operand' }
    def next_c(self) -> str:
        if self.input.startswith("//"):
            return { "value": self.take_while(lambda ch: ch != '\n'), "type": 'comment' }
        if self.peek() == '"':
            return { "value": self.take_string(), "type": 'string' }
        if self.peek().isnumeric():
            return { "value": self.take_while(isvalid), "type": 'number' }
        if self.peek().isalpha():
            return { "value": self.take_while(isvalid), "type": 'symbol' }
        return { "value": self.pop(), "type": 'operand' }
    def take_string(self):
        buf = self.pop()
        assert buf == '"'
        while self.peek() != None:
            ch = self.pop()
            buf += ch
            if ch == '"': break
        return buf
    def take_while(self, f):
        buf = ""
        while self.peek() != None and f(self.peek()):
            buf += self.pop()
        return buf
    def pop(self) -> str:
        if len(self.input) == 0: return None
        ch, self.input = self.input[0], self.input[1:]
        return ch
    def peek(self) -> str:
        if len(self.input) == 0: return None
        return self.input[0]
def isvalid(ch: str):
    return ch.isalnum() or ch in "_"

def tokenize(bs, lang, inp):
    out = []
    kwds = ["or", "and", "fn", "struct", "return", "if", "match", "for", "else"]
    toks = Tokenizer(lang, inp).collect()
    
    for i in range(len(toks)):
        tok = toks[i]
        next_tok = findnexttok(toks, i, 1)
        last_tok = findnexttok(toks, i, -1)

        if tok["type"] == None:
            out.append(bs4.NavigableString(tok["value"]))
        elif tok["type"] == "symbol" and tok["value"] in kwds:
            out.append(wraptag(bs, "keyword", tok["value"]))
        elif lang == "c" and tok["type"] == "symbol" and tok["value"].islower() and ((next_tok["value"] == "(" or next_tok["value"] == "!") if next_tok != None else False):
            out.append(wraptag(bs, "function", tok["value"]))
        elif lang == "c" and tok["type"] == "symbol" and ((next_tok["type"] == "symbol" and next_tok["value"] not in kwds) if next_tok != None else False):
            out.append(wraptag(bs, "type", tok["value"]))
        elif lang == "nasm" and tok["type"] == "symbol" and ((next_tok["type"] == "symbol" or next_tok["type"] == "number") if next_tok != None else False):
            out.append(wraptag(bs, "keyword", tok["value"]))
        else:
            out.append(wraptag(bs, tok["type"], tok["value"]))

    return out

def findnexttok(toks, i, inc):
    i+=inc
    next_tok = None
    while (next_tok == None or next_tok["type"] == None) and (i < len(toks) and i >= 0):
        if toks[i] != None and toks[i]["type"] == None and "\n" in toks[i]["value"]:
            return None
        next_tok = toks[i]
        i+=inc
    return next_tok
def wraptag(bs, tag, text):
    e: bs4.Tag = bs.new_tag("tok")
    e.attrs["type"] = tag
    if tag == "operand": e.attrs["o"] = text
    if tag == "symbol" and text.istitle(): e.attrs["titlecase"] = None
    e.append(bs4.NavigableString(text))
    return e


html_doc = open("index.template.html", "r")
soup = bs4.BeautifulSoup(html_doc, 'html.parser')

for code in soup.find_all("code"):
    lang = code.attrs.get("lang")
    pre: bs4.Tag = code.findChild("pre")
    if pre is None: continue
    pre.contents = tokenize(soup, lang, pre.get_text())

with open("index.html", "w") as o:
    o.write("<!-- this file is generated by slog/alloca2/__main__.py -->\n")
    o.write(str(soup))