module pushdown.rule;

import pushdown.node;

/// The rule interface is what all rules much extend from. Note that these don't have to be a template if you don't want them to be
interface Rule {
  Node result(Node[] nodes, Node[] next); /// Returns the result of the rule. If the rule is invalid for the given parameters, null is returned
}

private bool valid(T)(Node n) {
  static if(is(T : Node)) {
    if(cast(T)n is null)
      return false;
    return true;
  } else {
    return T.valid(n);
  }
}

/// For a sequence with a given length
class SequenceRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T...) : Rule {

  // static foreach(U; T) {
  //   static assert(is(U : Node) || is(U == Either));
  // }

  Node result(Node[] nodes, Node[] next) {
    if(nodes.length != T.length)
      return null;
    // it's kinda crazy that D just lets me do this
    string genConditions() {
      import std.string, std.conv;
      string ret = "";
      for(int i = 0; i < T.length; i++) {
        ret ~= `
          if(!valid!(T[_])(nodes[_]))
            return null;
        `.replace("_", i.to!string);
      }
      return ret;
    }
    mixin(genConditions);
    if(!extra(nodes, next))
      return null;
    return res(nodes);
  }
}

/// For an indefinite amount of things surrounded by two tokens
class EdgeRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T, U) : Rule {
  Node result(Node[] nodes, Node[] next) {
    if(nodes.length < 2)
      return null;
    if(valid!(T)(nodes[0]) && valid!(U)(nodes[$-1]) && extra(nodes, next))
      return res(nodes);
    return null;
  }
}

/// Similar to EdgeRule, except that it checks if the two given types are balanced
/// Usually you'd want to use this instead of EdgeRule
class BalancedEdgeRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T, U) : Rule {
  Node result(Node[] nodes, Node[] next) {
    if(nodes.length < 2)
      return null;
    if(valid!(T)(nodes[0]) && valid!(U)(nodes[$-1])) {
      // check balance
      int balance = 0;
      for(int i = 0; i < nodes.length; i++) {
        if(cast(T)nodes[i] !is null)
          balance++;
        else if(cast(U)nodes[i] !is null)
          balance--;
      }
      if(balance == 0 && extra(nodes, next)) {
        return res(nodes);
      }
    }
    return null;
  }
}

/// Only checks the first node
class StartRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T) : Rule {
  Node result(Node[] nodes, Node[] next) {
    if(nodes.length < 1)
      return null;
    if(valid!(T)(nodes[0]) && extra(nodes, next))
      return res(nodes);
  }
}

/// Only checks the last node
class EndRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T) : Rule {
  Node result(Node[] nodes, Node[] next) {
    if(nodes.length < 1)
      return null;
    if(valid!(T)(nodes[$-1]) !is null && extra(nodes, next))
      return res(nodes);
  }
}

/// Checks for a list with T as the item and U as the delimiter
/// `T U T U` => valid
/// `T U` => valid
/// `T U T U T` => valid
/// `T T U T` => invalid
class ListRule(Node delegate(Node[]) res, bool delegate(Node[], Node[]) extra, T, U) : Rule {
  Node result(Node[] nodes, Node[] next) {
    bool t = true;
    foreach(n; nodes) {
      if(t) {
        if(!valid!(T)(n))
          return null;
      } else {
        if(!valid!(U)(n))
          return null;
      }
      t = !t;
    }
    if(extra(nodes, next))
      return res(nodes);
    return null;
  }
}