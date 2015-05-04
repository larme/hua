(import os.path)

(import [hy.models.expression [HyExpression]]
        [hy.models.keyword [HyKeyword]]
        [hy.models.integer [HyInteger]]
        [hy.models.float [HyFloat]]
        [hy.models.string [HyString]]
        [hy.models.symbol [HySymbol]]
        [hy.models.list [HyList]]
        [hy.models.dict [HyDict]]
        [hy.compiler [checkargs]]
        [hy.macros]
        [hy.importer [import-file-to-hst]])

(import [hua.mlast :as ast]
        [hua.lua [tlast->src]])

(def -compile-table {})

(defn ast-str (s)
  (% "%s" s))

(defn builds [-type]
  "assoc decorated function to compile-table"
  (lambda [f]
    (assoc -compile-table -type f)
    f))

(defclass Result [object]
  [[--init--
    (fn [self &rest args &kwargs kwargs]
      (setv self.stmts [])
      (setv self.temp-vars [])
      (setv self.-expr nil)
      (setv self.--used-expr false)

      (for [kwarg kwargs]
        (unless (in kwarg ["stmts"
                           "expr"
                           "temp_vars"])
          (print "something wrong"))
        (setattr self kwarg (. kwargs [kwarg])))
      
      nil)]

   [expr
    (with-decorator property
      (defn expr [self]
        (setv self.--used-expr true)
        self.-expr))]
   [expr
    (with-decorator expr.setter
      (defn expr [self value]
        (setv self.--used-expr false)
        (setv self.-expr value)))]

   [expr?
    (fn [self]
      "Check whether I am a pure expression"
      (and self.-expr
           (empty? [])))]

   [force-expr
    (with-decorator property
      (defn force-expr [self]
        "Force the expression context of the Result"
        (if self.expr
          self.expr
          ;; FIXME
          (ast.Nil))))]

   [expr-as-stmt
    (fn [self]
      "Convert the Result's expression context to a statement

Unlike python, only function/method call can be pure expression statement"

      (if (and self.expr
               (instance? ast.Apply self.expr))
        (+ (Result) (apply Result [] {"stmts" [self.expr]}))
        (Result)))]

   [rename
    (fn [self new-names-]
      "Rename the Result's temporary variables to a `new-name`"
      (def new-names (if (coll? new-names-)
                       (list-comp (ast-str new-name-)
                                  [new-name- new-names-])
                       [new-names-]))

      (for [var self.temp-vars]
        (cond [(instance? ast.Id var)
               (setv var.nodes (get new-names 0))]
              [(instance? ast.Multi var)
               (do
                (def new-ids (list-comp (ast.Id new-name)
                                        [new-name new-names]))
                (setv var.exprs new-ids))]
              [true
               (raise "FIXME")]))
      (setv self.temp-vars []))]

   [--add--
    (fn [self other]
      (cond

       ;; ast.expr case come first because ast.Apply is both statement and expression. By default we will treat them as expression.
       [(ast.expr? other)
        (+ self (apply Result [] {"expr" other}))]
       [(ast.stat? other)
        (+ self (apply Result [] {"stmts" [other]}))]

       ;; FIXME
       [true
        (let [[result (Result)]]
          (setv result.stmts (+ self.stmts
                                other.stmts))
          (setv result.expr other.expr)
          (setv result.temp-vars other.temp-vars)
          result)]))]])

(defn -branch [results-]
  "make a branch out of a list of Result objects"
  (let [[results (list results-)]
        [ret (Result)]]
    (for [result (slice results 0 -1)]
      (+= ret result)
      (+= ret (.expr-as-stmt result)))
    (for [result (slice results -1)]
      (+= ret result))
    ret))

(defn -assign-expr-for-result [result var expr]
  "If the result's last statement is not ast.Return, append an ast.Set statement of assigning var to expr to the result."
  (when (or (empty? result.stmts)
            (not (instance? ast.Return
                            (get result.stmts -1))))
    (+= result (ast.Set var expr)))
  result)

(defclass HuaASTCompiler [object]
  [[--init--
    (fn [self module-name]
      (setv self.anon-fn-count 0)
      (setv self.anon-var-count 0)
      (setv self.module-name module-name)
      nil)]

   [get-anon-var
    (fn [self]
      (+= self.anon-var-count 1)
      (% "_hua_anon_var_%s" self.anon-var-count))]

   [get-anon-fn
    (fn [self]
      (+= self.anon-fn-count 1)
      (% "_hua_anon_fn_%s" self.anon-fn-count))]

   [compile-atom
    (fn [self atom-type atom]
      ;; (print atom-type)
      ;; (print atom)
      ;; (print (in atom-type -compile-table))
      ;; (print "compile-atom ======")
      (when (in atom-type -compile-table)
        ;; (print "compile-f: " (get -compile-table atom-type))
        ;; (print "atom: " atom)
        ;; (print "\n")
        (let [[compile-f (get -compile-table atom-type)]
              [ret (compile-f self atom)]]
          (if (instance? Result ret)
            ret
            (+ (Result) ret)))))]

   [compile
    (fn [self tree]
      ;;; FIXME compiler errors
      ;; (print "compile =====")
      (let [[-type (type tree)]]
        (.compile-atom self -type tree)))]

   [-compile-collect
    (fn [self exprs]
      "Collect the expression contexts from a list of compiled expression."
      (let [[compiled-exprs []]
            [ret (Result)]]
        (for [expr exprs]
          (+= ret (.compile self expr))
          (.append compiled-exprs ret.force_expr))
        (, compiled-exprs ret)))]

   [-compile-branch
    (fn [self exprs]
      (-branch (list-comp (.compile self expr) [expr exprs])))]

   ;;; FIXME no keyword and kwargs yet, maybe never
   [-parse-lambda-list
    (fn [self exprs]
      (def ll-keywords (, "&rest" "&optional"))
      (def ret (Result))
      (def args [])
      (def defaults [])
      (def varargs nil)
      (def lambda-keyword nil)
      (for [expr exprs]
        (if (in expr ll-keywords)
          ;; FIXME &optional error handling
          (setv lambda-keyword expr)
          (cond
           [(nil? lambda-keyword)
            (.append args expr)]
           [(= lambda-keyword "&rest")
            (if (nil? varargs)
              (setv varargs (str expr))
              (print "FIXME only one &rest error"))]
           [(= lambda-keyword "&optional")
            (do
             (if (instance? HyList expr)
               (if (not (= 2 (len expr)))
                 (print "FIXME optinal rags hould be bare names"
                        "or 2-item lists")
                 (setv (, k v) expr))
               (do
                (setv k expr)
                (setv v (.replace (HySymbol "nil") k))))
             (.append args k)
             (+= ret (.compile self v))
             (.append defaults ret.force_expr))])))
      (, ret args defaults varargs))]
   

   ;;; FIXME _storeize do we really need this?
   [-storeize
    (fn [self name]
      (if-not (.expr? name)
              (print "FIXME: type error")
              (setv name name.expr))

      ;;; FIXME multiple assign, index etc.
      (cond [(instance? (, ast.Id ast.Index ast.Multi) name)
             name]
            [true
             (print "FIXME: type error")]))]

   [compile-raw-list
    (with-decorator (builds list)
      (fn [self entries]
        (let [[ret (.-compile-branch self entries)]]
          (+= ret (.expr-as-stmt ret))
          ret)))]

   ;;; FIXME quote related. or no quote because we don't have macro?

   ;;; FIXME a lot of functions in between

   [compile-progn
    (with-decorator (builds "do") (builds "progn")
      (fn [self expression]
        (.pop expression 0)
        (.-compile-branch self expression)))]

   [compile-do-block
    (with-decorator (builds "do_block")
      (fn [self expression]
        (.pop expression 0)
        (def branch (.-compile-branch self expression))
        (def var-name (.get-anon-var self))
        (def var (ast.Multi (ast.Id var-name)))
        (setv branch
              (-assign-expr-for-result branch var branch.force-expr))
        (+ (Result)
           (ast.Local var)
           (ast.Do branch.stmts)
           (apply Result
                  []
                  {"expr" var "temp_vars" [var]}))))]

   [compile-if
    (with-decorator
      (builds "if")
      (apply checkargs [] {"min" 2 "max" 3})
      (fn [self expression]
        (.pop expression 0)
        (let [[condition (.compile self (.pop expression 0))]
              [body (.compile self (.pop expression 0))]
              [orel (if (empty? expression)
                      (Result)
                      (.compile self (.pop expression 0)))]
              [ret condition]
              
              [var-name (.get-anon-var self)]
              [var (ast.Multi (ast.Id var-name))]

              [expr-name (ast.Multi (ast.Id (ast-str var-name)))]]

          ;; we won't test if statements in body or orel because lua doesn't have official ternary operator support

          ;;          (+= ret (ast.Local [var]))
          (setv ret (+ (Result) (ast.Local var) ret))
          (setv body
                (-assign-expr-for-result body var body.force-expr))
          (setv orel
                (-assign-expr-for-result orel var orel.force-expr))
          (+= ret (ast.If ret.force-expr body.stmts orel.stmts))
          (+= ret (apply Result []
                         {"expr" expr-name "temp_vars" [expr-name
                                                        var]}))
          ret
          )))]

   ;;; FIXME break, assert etc.

   ;;; FIXME import/require

   [compile-index-expression
    (with-decorator
      (builds "get")
      (apply checkargs [] {"min" 2})
      (fn [self expr]
        (.pop expr 0)

        (def val (.compile self (.pop expr 0)))
        (def (, indexes ret) (.-compile-collect self expr))

        (when (not (empty? val.stmts))
          (+= ret val))

        (for [index indexes]
          (setv val (+ (Result)
                       (ast.Index val.force-expr
                                  index))))
        
        (+ ret val)))]

   [compile-multi
    (with-decorator (builds ",")
      (fn [self expr]
        (.pop expr 0)
        (def (, elts ret) (.-compile-collect self expr))
        (def multi (ast.Multi elts))
        (+= ret multi)
        ret))]
   
   [compile-require-macro
    (with-decorator (builds "require_macro")
      (fn [self expression]
        (.pop expression 0)
        (for [entry expression]
          (--import-- entry)
          (hy.macros.require entry self.module-name))
        (Result)))]

   [compile-compare-op-expression
    (with-decorator
      (builds "=*")
      (builds "<*")
      (builds "<=*")
      (checkargs 2)
      (fn [self expression]
        (def operator (.pop expression 0))
        (def op-id (ast.get-op-id operator))
        (def (, exprs ret) (.-compile-collect self expression))
        (+ ret (ast.Op op-id
                       (get exprs 0)
                       (get exprs 1)))))]
   
   [compile-unary-operator
    (with-decorator
      (builds "not" )
      (builds "len")
      (checkargs 1)
      (fn [self expression]
        (def operator (.pop expression 0))
        (def op-id (ast.get-op-id operator))
        (def operand (.compile self (.pop expression 0)))
        (+= operand (ast.Op op-id operand.expr))
        operand))]

   [compile-binary-operators
    (with-decorator
      (builds "and")
      (builds "or")
      (builds "%")
      (builds "/")
      (builds "//")
      (builds "^")
      ;; bitwise for lua 5.3
      (builds "|")
      (builds "bor")
      (builds "&")
      (builds "<<")
      (builds ">>")
      (builds "concat")
      (fn [self expression]
        (def operator (.pop expression 0))
        (def op-id (ast.get-op-id operator))
        
        (def ret (.compile self (.pop expression 0)))
        
        (for [child expression]
          (def left-expr ret.force-expr)
          (+= ret (.compile self child))
          (def right-expr ret.force-expr)
          (+= ret (ast.Op op-id left-expr right-expr)))
        (+ ret (ast.Paren ret.expr))))]

   [compile-add-and-mul-expression
    (with-decorator
      (builds "+")
      (builds "*")
      (fn [self expression]
        (if (> (len expression) 2)
          (.compile-binary-operators self expression)
          (do
           (def id-op {"+" (HyInteger 0) "*" (HyInteger 1)})
           (def op (.pop expression 0))
           (def arg (if (empty? expression)
                      (get id-op op)
                      (.pop expression 0)))
           (def expr (.replace (HyExpression [(HySymbol op)
                                              (get id-op op)
                                              arg])
                               expression))
           (.compile-binary-operators self expr)))))]

   [compile-sub-expression
    (with-decorator
      (builds "-")
      (fn [self expression]
        (if (> (len expression) 2)
          (.compile-binary-operators self expression)
          (do
           (def arg (get expression 1))
           (def ret (.compile self arg))
           (+= ret (ast.Op "sub" ret.force-expr))
           ret))))]

   [compile-expression
    (with-decorator (builds HyExpression)
      (fn [self expression]
        ;;; FIXME: macroexpand and "." and a lot more
        (setv expression (hy.macros.macroexpand expression
                                                self.module-name))
        (cond [(not (instance? HyExpression expression))
               (.compile self expression)]
              [(= expression [])
               (.compile-list self expression)]
              [true
               (let [[fun (get expression 0)]]
                 (cond [(instance? HyKeyword fun)
                        (print "FIXME: keyword call")]
                       [(instance? HyString fun)
                        (do
                         (setv ret (.compile-atom self fun expression))
                         (if (not (nil? ret))
                           ret
                           (.-compile-fun-call self expression)))]
                       [true
                        (let [[func (.compile self fun)]]
                          (def (, args ret)
                            (.-compile-collect self
                                               (slice expression 1)))
                          (def call (ast.Call func.expr
                                              args))
                          (+ func ret call))]))])))]

   [-compile-fun-call
    (fn [self expression]
      (setv fun (get expression 0))
      (setv func nil)
      (setv method-call? false)

      (when (.startswith fun ".")
        (setv method-call? true)
        (setv ofun fun)
        (setv fun (HySymbol (slice ofun 1)))
        (.replace fun ofun)

        (when (< (len expression) 2)
          (print "FIXME error message"))

        ;; FIXME: this line should we ensure the compiled result is a string?
        (setv method-name (ast.String (ast-str fun)))
        (setv func (.compile self (.pop expression 1))))
      (when (nil? func)
        (setv func (.compile self fun)))

      ;; FIXME: no kwargs for lua?
      (setv (, args ret) (.-compile-collect self
                                            (slice expression 1)))

      (setv call (if method-call?
                   (ast.Invoke func.expr
                               method-name
                               args)
                   (ast.Call func.expr
                             args)))

      (+ func ret call))]

   [compile-def-expression
    (with-decorator
      (builds "def")
      (checkargs 2)
      (fn [self expression]
        (.-compile-define self
                          (get expression 1)
                          (get expression 2))))]

   [-compile-define
    (fn [self name result]
      (setv str-name (% "%s" name))

      ;;; FIXME test builtin
      (setv result (.compile self result))
      (setv ident (.compile self name))

      (if (and (empty? ident.stmts)
               (instance? (, ast.Multi ast.Id) ident.expr))
        (setv ident ident.expr)
        (raise "FIXME: identities required"))
      
      (if (empty? result.temp-vars)
        (+= result (ast.Local ident
                              result.force-expr))
        (.rename result (if (instance? ast.Id ident)
                          ident.name
                          (list-comp (. idn name)
                                     [idn ident.nodes]))))

      (+= result ident)
      result)]

   [compile-setv-expression
    (with-decorator
      (builds "setv")
      (checkargs 2)
      (fn [self expression]
        (let [[name (get expression 1)]
              [result (get expression 2)]]
          (setv result (.compile self result))
          (setv ld-name (.compile self name))

          (when (and (instance? ast.Multi ld-name.expr)
                     (not (empty? result.temp-vars)))
            (.rename result
                     (list-comp (.get-anon-var self)
                                [i (range (.count ld-name.expr))])))
          
          ;; FIXME do we need this? (setv st-name (.-storeize self ld-name))

          (setv result (+ result
                          (ast.Set [ld-name.expr]
                                   [result.force-expr])
                          ld-name))
          result)))]

   [compile-for-expression
    (with-decorator
      (builds "for*")
      (apply checkargs [] {"min" 1})
      (fn [self expression]
        (.pop expression 0)
        (def args (.pop expression 0))
        (when (not (instance? HyList args))
          (raise (.format "FIXME for expects a list, received `{0}'"
                          (. (type args) --name--))))
        ;; FIXME for args number checkign
        (def (, target-name iterable) args)

        (def target (.-storeize self (.compile self target-name)))

        (def body (.-compile-branch self expression))
        (+= body (.expr-as-stmt body))

        (def ret (Result))
        (+= ret (.compile self iterable))

        ;; two form of for
        ;; generic for: (for* [expr iterable] body)
        ;; numeric for: (for* [expr [init final step]] body)

        (if (is HyList (type iterable)) ; this looks ugly, but it prevent HyExpression go into the true branch
          (+= ret (ast.Fornum target ret.force-expr.nodes body.stmts))
          (+= ret (ast.Forin target ret.force-expr body.stmts)))
        ret))]

   [compile-integer
    (with-decorator (builds HyInteger)
      (fn [self number]
        (ast.Number number)))]

   [compile-float
    (with-decorator (builds HyFloat)
      (fn [self number]
        (ast.Number number)))]

   [compile-string
    (with-decorator (builds HyString)
      (fn [self string]
        (ast.String string)))]

   [compile-symbol
    (with-decorator (builds HySymbol)
      (fn [self symbol]
        ;;; FIXME more complex case

        (if (in "." symbol)
          (do
           (setv (, glob local) (.rsplit symbol "." 1))
           (setv glob (.replace (HySymbol glob) symbol))
           (setv ret (.compile-symbol self glob))
           (setv ret (ast.Index ret (ast.String (ast-str local))))
           ret)
          (cond
           [(= symbol "True") (ast.MLTrue)]
           [(= symbol "False") (ast.MLFalse)]
           [(or (= symbol "None")
                (= symbol "nil"))
            (ast.Nil)]
           [(= symbol "DOTDOTDOT") (ast.Dots)]
           [true (ast.Id (ast-str symbol))]))))]

   [compile-list
    (with-decorator (builds HyList)
      (fn [self expression]
        (setv (, elts ret) (.-compile-collect self expression))
        (+= ret (ast.Table elts nil))
        ret))]

   [compile-function-def
    (with-decorator
      (builds "lambda")
      (builds "fn")
      (apply checkargs [] {"min" 1})
      (fn [self expression]
        (.pop expression 0)
        (def arglist (.pop expression 0))
        (def (, ret -args defaults vararg)
          (.-parse-lambda-list self arglist))
        (def args (list-comp (. (.compile self arg) expr)
                             [arg -args]))
        (def body (Result))

        ;; FIXME &optional parameters
        ;; use var = var == nil and default_value or var

        (when vararg
          (.append args (ast.Dots))
          (+= body (apply Result
                          []
                          {"stmts" [(ast.Local [(ast.Id vararg)]
                                               [(ast.Table
                                                 [(ast.Dots)]
                                                 nil)])]})))

        (+= body (.-compile-branch self expression))

        (when body.expr
          (+= body (ast.Return body.expr)))

        (+= ret (ast.Function args
                              body.stmts))
        ret))]

   [compile-return
    (with-decorator
      (builds "return")
      (apply checkargs [] {"min" 1})
      (fn [self expression]
        (.pop expression 0)
        (def (, return-exprs ret) (.-compile-collect self expression))
        (+ ret (ast.Return return-exprs))))]

   [compile-dispatch-reader-macro
    (with-decorator
      (builds "dispatch_reader_macro")
      (checkargs 2)
      (fn [self expression]
        (.pop expression 0)
        (def str-char (.pop expression 0))
        (when (not (type str-char))
          (raise "FIXME"))
        
        (def module self.module-name)
        (def expr (hy.macros.reader-macroexpand str-char
                                                (.pop expression 0)
                                                module))
        (.compile self expr)))]

   [compile-dict
    (with-decorator (builds HyDict)
      (fn [self m]
        (def (, kv ret) (.-compile-collect self m))
        (def length (len kv))
        (if (= length 1)
          (+= ret (ast.Table kv  nil))
          (do
           (setv half-length (int (/ length 2)))
           (setv hash-part (dict-comp (get kv (* 2 i))
                                      (get kv (inc (* 2 i)))
                                      [i (range half-length)]))
           (+= ret (ast.Table nil hash-part))           ))

        ret))]])

(defn compile-file-to-string [filename]
  (def metalua-ast (let [[hst (import-file-to-hst filename)]
                         ;; use filename as module name here since the
                         ;; only function of module name in hua
                         ;; compiler is to track which file requires
                         ;; which macros
                         [compiler (HuaASTCompiler filename)]]
                     (.compile compiler hst)))
  (def stmts (ast.to-ml-table metalua-ast.stmts))
  (tlast->src stmts))

(defn compile-file [filename]
  (def result (compile-file-to-string filename))
  (def (, basename extname) (os.path.splitext filename))
  (def lua-filename (+ basename ".lua"))
  (with [[lua-f (open lua-filename "w")]]
        (.write lua-f result)))

