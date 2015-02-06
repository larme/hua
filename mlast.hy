(import [numbers [Real]])

(import [lua [lt->dict]])

(def *op-ids* {:+ "add"
               :- "sub"
               :* "mul"
               :/ "div"
               :// "idiv"
               :% "mod"
               :^ "pow"
               :& "band"
               :bor "bor"
               :<< "shl"
               :>> "shr"
               :concat "concat"
               := "eq"
               :< "lt"
               :<= "le"
               :and "and"
               :or "or"
               :not "not"
               :len "len"})

;;; given the operator name in hua, return corresponding op-id
(defn get-op-id [op]
  (if (= op "|")
    "bor"
    (get *op-ids* (keyword op))))

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
        (if (instance? Multi self)
          nodes
          res)))]])

;;; return an ast tree as {tag=tag, nodes=[node1, node2, ...]} form
;;; also "slice unquote" Multi ast
(defn -to-ml-table-pass-1 [tree]
  (cond [(instance? (, list tuple) tree)
         (do
          (def nodes [])
          (for [node tree]
            (def elt (-to-ml-table-pass-1 node))
            ;; slice unquoting Multi ast
            (if (and (instance? dict elt)
                     (= (get elt "tag") "Multi"))
              (+= nodes (get elt "nodes"))
              (.append nodes elt)))
          nodes)]
        [(or (instance? Real tree)
             (string? tree))
         tree]
        [(instance? ASTNode tree)
         (do
          (def res {"tag" tree.tag})
          (def nodes (-to-ml-table-pass-1 tree.nodes))
          (.update res {"nodes" nodes})
          res)]))

(defn -to-ml-table-pass-2 [tree]
  (cond [(instance? (, list tuple) tree)
         (lt->dict (list-comp (-to-ml-table-pass-2 node)
                              [node tree]))]
        [(instance? dict tree)
         (let [[res {"tag" (get tree "tag")}]
               [nodes (-to-ml-table-pass-2 (get tree "nodes"))]]
           (.update res nodes)
           res)]
        [(or (instance? Real tree)
             (string? tree))
         tree]))

(defn to-ml-table [tree]
  (-> tree
      -to-ml-table-pass-1
      -to-ml-table-pass-2))


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

(defclass Paren [Expr]
  [[tag "Paren"]
   [--init--
    (fn [self expr]
      (setv self.nodes [expr])
      nil)]])

;;; not a metalua AST, just for multiple assignment/return
(defclass Multi [Expr]
  [[tag "Multi"]
   [--init--
    (fn [self exprs]
      (setv self.exprs exprs)
      nil)]
   [nodes
    (with-decorator property
      (fn [self]
        (def ret (cond [(coll? self.exprs)
                        self.exprs]
                       [true
                        [self.exprs]]))
        ret))]])

(defn convert-to-multi [node]
  (cond [(instance? Multi node)
         node]
        [(instance? Expr node)
         (Multi [node])]
        [(coll? node)
         (Multi node)]))

;;; lhs
(defclass Id [LHS]
  [[tag "Id"]
   [--init--
    (fn [self name]
      (setv self.name name)
      nil)]
   [--repr--
    (fn [self]
      (% (.gen-repr-template self) self.name))]
   [nodes
    (with-decorator property
      (fn [self]
        [self.name]))]])

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
    (fn [self lhss rhss]
      (setv self.lhss (convert-to-multi lhss))
      (setv self.rhss (convert-to-multi rhss))
      nil)]
   [nodes
    (with-decorator property
      (fn [self]
        [[self.lhss] [self.rhss]]))]])

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
    (fn [self lhss &optional [rhss nil]]
      (setv self.lhss (convert-to-multi lhss))
      (setv self.rhss (convert-to-multi rhss))
      nil)]
   [nodes
    (with-decorator property
      (fn [self]
        (def lhss-nodes [self.lhss])
        (def rhss-nodes (if (nil? self.rhss)
                          []
                          [self.rhss]))
        [lhss-nodes rhss-nodes]))]])

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



