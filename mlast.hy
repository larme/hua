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
  [[--init--
    (fn [self]
      (setv self.nodes [])
      nil)]
   [gen-repr-template
    (fn [self]
      (.join "" ["<class " self.__class__.__name__ " %s at " (hex (id self)) ">"]))]
   [to-table
    (fn [self]
      (let [[res {"tag" self.tag}]
            [-nodes (list-comp (cond [(instance? ASTNode node)
                                      (.to-table node)]
                                     [(instance? dict node)
                                      (dict-comp key (.to-table (get node key)) [key (.keys node)])]
                                     [(instance? list node)
                                      (lt->dict (list-comp (.to-table subnode)
                                                           [subnode node]))]
                                     [(or (instance? Real node)
                                          (string? node))
                                      node]
                                     [true
                                      (. node expr nodes)])
                               [node self.nodes])]
            [nodes (lt->dict -nodes)]]
        (.update res nodes)
        res))]])

(defclass Stat [ASTNode])

(defclass Expr [ASTNode])

(defclass LHS [Expr])

(defclass Apply [Stat Expr])

;;; (simple) test functions
(defn expr? [o]
  (instance? Expr o))

(defn stat? [o]
  (instance? Stat o))

(defn block? [o]
  (and (coll? o)
       (every? stat? o)))


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
   [--repr--
    (fn [self]
      (% (.gen-repr-template self) (get self.nodes 0)))]])

(defclass String [Expr]
  [[tag "String"]
   [--init--
    (fn [self value]
      (setv self.value value)
      (setv self.nodes [value])
      None)]
   [--repr--
    (fn [self]
      (% (.gen-repr-template self) (get self.nodes 0)))]])

;;; lhs
(defclass Id [LHS]
  [[tag "Id"]
   [--init--
    (fn [self ident]
      (setv self.nodes [ident])
      nil)]
   [--repr--
    (fn [self]
      (% (.gen-repr-template self) (get self.nodes 0)))]])

(defclass Index [LHS]
  [[tag "Index"]
   [--init--
    (fn [self expr1 expr2]
      (setv self.nodes [expr1 expr2])
      nil)]])

;;; Statements
(defclass Set [Stat]
  [[tag "Set"]
   [--init--
    (fn [self idents exprs]
      (setv self.nodes [idents exprs])
      nil)]])

(defclass Local [Stat]
  [[tag "Local"]
   [--init--
    (fn [self idents &optional [exprs nil]]
      (setv self.nodes [idents])
      (if (nil? exprs)
        (.append self.nodes [])
        (.append self.nodes exprs))
      nil)]])

(defclass If [Stat]
  [[tag "If"]
   [--init--
    (fn [self expr1 block1 &rest rest]
      (setv self.nodes [expr1 block1])
      (+= self.nodes rest)
      nil)]])

;;; test
;; (import [lua [init-lua lua lua-astc -dict->ltable]])
;; (setv test-expr (Local [(Id "a") (Id "b")] [(Number 1)]))
;; (setv test-expr2 (Set [(Id "a") (Id "b")] [(Number 1) (Number 3)]))
;; (setv test-3 (If (MLTrue) [test-expr2] [test-expr2]))
;; (print (.to-table test-expr))
;; ;(print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-table test-expr2)))))
;; ;(print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-table test-3)))))

;; (print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-table (Index (Index (Id "a") (Number 1)) (Id "b")))))))



