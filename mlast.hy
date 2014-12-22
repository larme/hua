(import [numbers [Real]])

(import [lua [lt->dict]])

(def *op-id* ["add"
              "sub"
              "mul"
              "div"
              "mod"
              "pow"
              "concat"
              "eq"
              "lt"
              "le"
              "and"
              "or"
              "not"
              "len"])

(defclass ASTNode [object]
  [[to-table
    (fn [self]
      (let [[res {"tag" self.tag}]
            [-nodes (list-comp (.to-table node)
                               [node self.nodes])]
            [nodes (lt->dict -nodes)]]
        (.update res nodes)))]])

(defclass Stat [ASTNode]
  [[category ["stat"]]])

(defclass Expr [ASTNode]
  [[category ["expr"]]])

(defclass LHS [Expr]
  [[category ["expr lhs"]]])

(defclass Apply [Expr]
  [[category ["expr apply"]]])

(defclass Nil [Expr]
  [[tag "Nil"]])

(defclass Dots [Expr]
  [[tag "Dots"]])

(defclass MLTrue [Expr]
  [[tag "True"]])

(defclass MLFalse [Expr]
  [[tag "False"]])

(defclass Number [Expr]
  [[tag "Number"]
   [--init--
    (fn [self value]
      (setv self.value value)
      (setv self.nodes [value])
      None)]
   [to-table
    (fn [self]
      self.value)]])

(defclass String [Expr]
  [[tag "String"]
   [--init--
    (fn [self value]
      (setv self.value value)
      (setv self.nodes [value])
      None)]
   [to-table
    (fn [self]
      self.value)]])

;;; lhs
(defclass Id [LHS]
  [[tag "Id"]
   [--init--
    (fn [self ident]
      (setv self.nodes [ident])
      nil)]])
