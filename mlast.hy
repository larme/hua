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
   [--repr--
    (fn [self]
      (% (.gen-repr-template self) (% "nodes: %s" self.nodes)))]
   [to-ml-table
    (fn [self]
      (let [[res {"tag" self.tag}]
            [-nodes (list-comp (cond [(instance? ASTNode node)
                                      (.to-ml-table node)]
                                     [(instance? dict node)
                                      (dict-comp key (.to-ml-table (get node key)) [key (.keys node)])]
                                     [(instance? (, list tuple) node)
                                      (lt->dict (list-comp (.to-ml-table subnode)
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

(defclass Function [Expr]
  [[tag "Function"]
   [--init--
    (fn [self args body]
      (setv self.args args)
      (setv self.body body)
      nil)]
   [nodes
    (with-decorator property
      (defn nodes [self]
        [self.args self.body]))]])

;;; for metalua ast Table internal usage
(defclass -Pair [ASTNode]
  [[tag "Pair"]
   [--init--
    (fn [self p1 p2]
      (setv self.nodes [p1 p2])
      nil)]])

(defclass Table [Expr]
  [[tag "Table"]
   [--init--
    (fn [self array-part hash-part]
      (setv self.array-part array-part)
      (setv self.hash-part hash-part)
      nil)]
   [nodes
    (with-decorator property
      (defn nodes [self]
        (let [[array-list (if (nil? self.array-part)
                            []
                            self.array-part)]
              [hash-part (if (nil? self.hash-part)
                           []
                           (list-comp (-Pair key value)
                                      [(, key value) (.items self.hash-part)]))]]
          (+ array-list hash-part))))]])

(defclass Op [Expr]
  [[tag "Op"]
   [--init--
    (fn [self opid e1 &optional [e2 nil]]
      (setv self.opid opid)
      (setv self.e1 e1)
      (setv self.e2 e2)
      nil)]
   [nodes
    (with-decorator property
      (defn nodes [self]
        (let [[ret [self.opid self.e1]]]
          (if self.e2
            (+ ret [self.e2])
            ret))))]])

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

(defclass If [Stat]
  [[tag "If"]
   [--init--
    (fn [self expr1 block1 &rest rest]
      (setv self.nodes [expr1 block1])
      (+= self.nodes rest)
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

(defclass Return [Stat]
  [[tag "Return"]
   [--init--
    (fn [self return-exprs]
      (if (coll? return-exprs)
        (setv self.nodes return-exprs)
        (setv self.nodes [return-exprs]))
      nil)]])

;;; Apply
(defclass Call [Apply]
  [[tag "Call"]
   [--init--
    (fn [self func args]
      (setv self.func func)
      (setv self.args args)
      nil)]
   [nodes
    (with-decorator property
      (defn nodes [self]
        (+ [self.func] self.args)))]])

(defclass Invoke [Apply]
  [[tag "Invoke"]
   [--init--
    (fn [self obj method args]
      (setv self.obj obj)
      (setv self.method method)
      (setv self.args args)
      nil)]
   [nodes
    (with-decorator property
      (defn nodes [self]
        (+ [self.obj self.method] self.args)))]])

;;; test
;; (import [lua [init-lua lua lua-astc -dict->ltable]])
;; (setv test-expr (Local [(Id "a") (Id "b")] [(Number 1)]))
;; (setv test-expr2 (Set [(Id "a") (Id "b")] [(Number 1) (Number 3)]))
;; (setv test-3 (If (MLTrue) [test-expr2] [test-expr2]))
;; (print (.to-ml-table test-expr))
;; ;(print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-ml-table test-expr2)))))
;; ;(print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-ml-table test-3)))))

;; (print (.ast-to-src lua-astc lua-astc (.table-from lua (-dict->ltable lua (.to-ml-table (Index (Index (Id "a") (Number 1)) (Id "b")))))))



