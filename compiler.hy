(import [hy.models.expression [HyExpression]]
        [hy.models.keyword [HyKeyword]]
        [hy.models.integer [HyInteger]]
        [hy.models.float [HyFloat]]
        [hy.models.string [HyString]]
        [hy.models.symbol [HySymbol]]
        [hy.models.list [HyList]]
        [hy.models.dict [HyDict]])

(import hy.macros)

(import mlast)

(setv ast mlast)

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
          (ast.Id "None"))))]

   [expr-as-stmt
    (fn [self]
      "Convert the Result's expression context to a statement"
      (if (and self.expr
               (not (and (instance? ast.Id self.expr)
                         (not (empty? self.stmts)))))
        ;; FIXME?
        (+ (Result) self.expr)
        (Result)))]

   [rename
    (fn [self new-name-]
      "Rename the Result's temporary variables to a `new-name`"
      (let [[new-name (ast-str new-name-)]]
        (for [var self.temp-vars]
          (if (instance? ast.Id var)
            (setv var.nodes [new-name])
            ;; FIXME
            "nothing"))
        (setv self.temp-vars [])))]

   [--add--
    (fn [self other]
      (cond
       [(ast.stat? other)
        (+ self (apply Result [] {"stmts" [other]}))]
       [(ast.expr? other)
        (+ self (apply Result [] {"expr" other}))]

       ;; FIXME
       [true
        (let [[result (Result)]]
          (setv result.stmts (+ self.stmts
                                other.stmts))
          (setv result.expr other.expr)
          (setv result.temp-vars other.temp-vars)
          result)]))]

   ])

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

;;; FIXME: checkargs

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
      (print "compile-atom ======")
      (when (in atom-type -compile-table)
        (print "compile-f: " (get -compile-table atom-type))
        (print "atom: " atom)
        (print "\n")
        (let [[compile-f (get -compile-table atom-type)]
              [ret (compile-f self atom)]]
          (if (instance? Result ret)
            ret
            (+ (Result) ret)))))]

   [compile
    (fn [self tree]
      ;;; FIXME compiler errors
      (print "compile =====")
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

   ;;; FIXME parse lambda list

   ;;; FIXME _storeize do we really need this?
   [-storeize
    (fn [self name]
      (if-not (.expr? name)
              (print "FIXME: type error")
              (setv name name.expr))

      (print "xixixixi" name)
      ;;; FIXME multiple assign, index etc.
      (cond [(instance? (, ast.Id ast.Index) name)
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

   [compile-if
    (with-decorator (builds "if")
      (fn [self expression]
        (.pop expression 0)
        (let [[condition (.compile self (.pop expression 0))]
              [body (.compile self (.pop expression 0))]
              [orel (if (empty? expression)
                      (Result)
                      (.compile self (.pop expression 0)))]
              [ret condition]
              
              [var-name (.get-anon-var self)]
              [var (ast.Id var-name)]

              [expr-name (ast.Id (ast-str var-name))]]

          ;; we won't test if statements in body or orel because lua doesn't have official ternary operator support

          ;;          (+= ret (ast.Local [var]))
          (setv ret (+ (Result) (ast.Local [var]) ret))
          (+= body (ast.Set [var] [body.force-expr]))
          (+= orel (ast.Set [var] [orel.force-expr]))
          (+= ret (ast.If ret.force-expr body.stmts orel.stmts))
          (+= ret (apply Result []
                         {"expr" expr-name "temp_vars" [expr-name
                                                        var]}))
          ret
          )))]

   ;;; FIXME break, assert etc.

   ;;; FIXME import/require

   [compile-require-macro
    (with-decorator (builds "require_macro")
      (fn [self expression]
        (.pop expression 0)
        (for [entry expression]
          (--import-- entry)
          (hy.macros.require entry self.module-name))
        (Result)))]

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
                        (.-compile-fun-call self expression)]))])))]

   [-compile-fun-call
    (fn [self expression]
      (setv fun (get expression 0))
      (setv func nil)
      (setv ret (.compile-atom self fun expression))
      (if (not (nil? ret))
        ret
        (do
         (when (.startswith fun ".")
           (print "FIXME method call"))
         (when (nil? func)
           (setv func (.compile self fun)))

         ;;; FIXME: no kwargs for lua?

         (setv (, args ret) (.-compile-collect self
                                               (slice expression 1)))
         (+= ret (ast.Call func.expr
                           args))

         (+ func ret))))]

   [compile-def-expression
    (with-decorator (builds "def")
      (fn [self expression]
        (.-compile-define self
                          (get expression 1)
                          (get expression 2))))]

   [-compile-define
    (fn [self name result]
      (setv str-name (% "%s" name))

      ;;; FIXME test builtin
      (setv result (.compile self result))
      (setv ld-name (.compile self name))
      
      (if (and (not (empty? result.temp-vars))
               (instance? HyString name)
               (not (in "." name)))
        (.rename result name)
        (do
         (setv st-name (.-storeize self ld-name))
         (+= result (ast.Local [st-name]
                               [result.force-expr]))))

      (+= result ld-name)
      result)]

   [compile-local-expression
    (with-decorator (builds "local")
      (fn [self expression]
        (.pop expression 0)
        (setv results (.-compile-collect self expression))
        (setv locals (get results 0))
        (+ (Result) (ast.Local locals))))]

   
   [compile-setv-expression
    (with-decorator (builds "setv")
      (fn [self expression]
        (let [[name (get expression 1)]
              [result (get expression 2)]]
          (setv result (.compile self result))
          (setv ld-name (.compile self name))
          ;; FIXME do we need this? (setv st-name (.-storeize self ld-name))
          (+= result (ast.Set [ld-name.expr]
                              [result.force-expr]))
          result)))]

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
        (print "yo")
        (print symbol)
        (if (in "." symbol)
          (do
           (print "yoyo?")
           (setv (, glob local) (.rsplit symbol "." 1))
           (print glob local)
           (setv glob (.replace (HySymbol glob) symbol))
           (print glob)
           (setv ret (.compile-symbol self glob))
           (print ret)
           (setv ret (ast.Index ret (ast.String (ast-str local))))
           ret)
          (do
           (print "hehe?" (ast.Id (ast-str symbol)))
           (ast.Id (ast-str symbol))))))]

   [compile-list
    (with-decorator (builds HyList)
      (fn [self expression]
        (setv (, elts ret) (.-compile-collect self expression))
        (+= ret (ast.Table elts nil))
        ret))]

   [compile-dict
    (with-decorator (builds HyDict)
      (fn [self m]
        (setv (, kv ret) (.-compile-collect self m))
        (setv half-length (int (/ (len kv) 2)))
        (setv hash-part (dict-comp (get kv (* 2 i))
                                   (get kv (inc (* 2 i)))
                                   [i (range half-length)]))
        (+= ret (ast.Table nil hash-part))
        ret))]
   ])



