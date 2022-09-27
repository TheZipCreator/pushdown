# Pushdown
Pushdown is a parsing library utilizing a Pushdown Automaton. It makes heavy use of D's templating and metaprogramming features. Example:
```d
import pushdown;
// define some custom nodes
class Token(string type) : Node {
  char value;
  
  this(char value) {
    this.value = value;
  }

  override string toString() {
    import std.conv : to;
    return value.to!string;
  }
}

class Expression : Node {
  Node lhs;
  Node op;
  Node rhs;

  this(Node lhs, Node op, Node rhs) {
    this.lhs = lhs;
    this.op = op;
    this.rhs = rhs;
  }

  override string toString() {
    return "expr("~lhs.toString~" "~op.toString~" "~rhs.toString~")";
  }
}

class Assignment : Node {
  Token!"identifier" lvalue;
  Node rvalue;

  this(Node lvalue, Node rvalue) {
    this.lvalue = cast(Token!"identifier")lvalue; // note: dangerous. Only do this if you're 100% sure it will be that type
    this.rvalue = rvalue;
  }

  override string toString() {
    return "assign("~lvalue.toString~" "~rvalue.toString()~")";
  }
}

class Block : Node {
  Node[] children;

  this(Node[] children) {
    this.children = children;
  }

  override string toString() {
    string s = "block(";
    foreach(size_t i, child; children) {
      if(i > 0)
        s ~= " ";
      s ~= child.toString();
    }
    return s~")";
  }
}

// define a term
alias Term = Either!(Token!"number", Token!"identifier", Expression);
// test some things with term
assert(Term.valid(new Token!"number"('3')));
assert(Term.valid(new Token!"identifier"('x')));
assert(Term.valid(new Expression(new Token!"number"('3'), new Token!"operator"('+'), new Token!"number"('4'))));
assert(!Term.valid(new Token!"operator"('+')));
// a very simplistic lexer - splits the string into chars and assigns each char a type
Node[] lex(string s) {
  Node[] ret;
  foreach(char c; s) {
    void add(string type)() {
      ret ~= new Token!type(c);
    }
    switch(c) {
      case '~':
      case '+':
      case '-':
      case '*':
      case '/':
      case '%':
        add!"operator";
        break;
      case '0': .. case '9':
        add!"number";
        break;
      case '=':
        add!"assign";
        break;
      case ';':
        add!"semicolon";
        break;
      case '{':
        add!"lbrace";
        break;
      case '}':
        add!"rbrace";
        break;
      default:
        add!"identifier";
    }
  }
  return ret;
}
// lex something our lexer
Node[] nodes = lex("{x=3+2*4;{xyz}y=6/2/x+9;}z=z+1;");
// function to find the precedence of operators
int precedence(Node n) {
  if(auto op = cast(Token!"operator")n) {
    final switch(op.value) {
      case '~':
        return 1;
      case '+':
      case '-':
        return 2;
      case '*':
      case '/':
      case '%':
        return 3;
    }
  }
  return 0;
}
// create our parser
Parser parser = cast(Parser)[
  new SequenceRule!(
    // action: what to do with the nodes if parsing succeeds
    (Node[] nodes) => new Expression(nodes[0], nodes[1], nodes[2]),
    // extra:  extra things to check for a successful parse. In this case, checking operator precedence
    (Node[] nodes, Node[] next) => 
      next.length > 0 // make sure we can do lookahead
        ? precedence(nodes[1]) >= precedence(next[0]) // if so, make sure precedence of this is not lower than next
        : true, // otherwise just sucessfully parse
    // list of nodes to check for
    Term, Token!"operator", Term
  ),
  new SequenceRule!(
    (Node[] nodes) => new Assignment(nodes[0], nodes[2]),
    (Node[] nodes, Node[] next) => true, // always successfully parse
    Token!"identifier", Token!"assign", Term, Token!"semicolon"
  ),
  new BalancedEdgeRule!(
    (Node[] nodes) => new Block(nodes[1..$-1]),
    (Node[] nodes, Node[] next) => true,
    Token!"lbrace", Token!"rbrace"
  )
];
// parse
Node[] res = parser.parse(nodes);
import std.conv;
// easy way to check an entire tree
assert(res.to!string == "[block(assign(x expr(3 + expr(2 * 4))) block(x y z) assign(y expr(expr(expr(6 / 2) / x) + 9))), assign(z expr(z + 1))]");
```