module pushdown.node;

/// Represents a single node in the AST
interface Node {
  string toString();
}

/// Used for when there's two or more possible nodes that can appear somewhere. To be used in combination with rules
class Either(T...) {
  static bool valid(V)(V v) {
    foreach(U; T) {
      if(cast(U)v !is null)
        return true;
    }
    return false;
  }
}