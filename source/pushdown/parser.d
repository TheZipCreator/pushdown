module pushdown.parser;

import pushdown;

static Node[] parse(Rule[] rules, Node[] nodes) {
  Node[] stack;
  for(int i = 0; i < nodes.length; i++) {
    stack ~= nodes[i];
    bool reduced = true;
    while(reduced) {
      reduced = false;
      outer:
      for(int j = 0; j < stack.length; j++) {
        Node[] seg = stack[j..$];
        foreach(Rule r; rules) {
          if(Node res = r.result(seg, nodes[i+1..$])) {
            stack = stack[0..j];
            stack ~= res;
            reduced = true;
            break outer;
          }
        }
      }
    }
  }
  return stack;
}

alias Parser = Rule[];