(import [hy.models.expression [HyExpression]]
        [hy.models.integer [HyInteger]]
        [hy.models.float [HyFloat]]
        [hy.models.string [HyString]]
        [hy.models.symbol [HySymbol]])

(import mlast)

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
          (mlast.Id "None"))))]

   [expr-as-stmt
    (fn [self]
      "Convert the Result's expression context to a statement"
      (print "expr-as-stmt called?")
      (print "result stmts:" (. self stmts))
      (print "result expr:" (. self expr nodes))
      (print "\n")
      (if (and self.expr
               (not (and (instance? mlast.Id self.expr)
                         (not (empty? self.stmts)))))
        ;; FIXME?
        (do
         (print "asldfj: " self.expr "\n")
         (+ (Result) self.expr))
        (do
         (print "akdsfjlakfsd")
         (print (. self expr nodes))
         (print (and self.expr
                     (not (and (instance? mlast.Id self.expr)
                               (not (empty? self.stmts))))) "\n")
         (Result))))]

   [rename
    (fn [self new-name-]
      "Rename the Result's temporary variables to a `new-name`"
      (let [[new-name (ast-str new-name-)]]
        (for [var self.temp-vars]
          (if (instance? mlast.Id var)
            (setv var.nodes [new-name])
            ;; FIXME
            "nothing"))
        (setv self.temp-vars [])))]

   [--add--
    (fn [self other]
      (cond
       [(mlast.stat? other)
        (+ self (apply Result [] {"stmts" [other]}))]
       [(mlast.expr? other)
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
          (.append compiled-exprs (ret.force_expr)))
        (, compiled-exprs ret)))]

   [-compile-branch
    (fn [self exprs]
      (-branch (list-comp (.compile self expr) [expr exprs])))]

   ;;; FIXME parse lambda list

   ;;; FIXME _storeize
   [-storeize
    (fn [self name]
      (if-not (.expr? name)
              (print "FIXME: type error")
              (setv name name.expr))

      ;;; FIXME multiple assign, index etc.
      (cond [(instance? mlast.Id name)
             name]
            [true
             (print "FIXME: type error")]))]

   [compile-raw-list
    (with-decorator (builds list)
      (fn [self entries]
        (let [[ret (.-compile-branch self entries)]]
          (print "end?" (.expr-as-stmt ret))
          (print "\n")
          (+= ret (.expr-as-stmt ret)))))]

   ;;; FIXME quote related

   ;;; FIXME a lot of functions in between

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
              [var (mlast.Id var-name)]

              [expr-name (mlast.Id (ast-str var-name))]]

          ;; we won't test if statements in body or orel because lua doesn't have official ternary operator support

          ;;          (+= ret (mlast.Local [var]))
          (setv ret (+ (Result) (mlast.Local [var]) ret))
          (+= body (mlast.Set [var] [body.force-expr]))
          (+= orel (mlast.Set [var] [orel.force-expr]))
          (+= ret (mlast.If ret.force-expr body.stmts orel.stmts))
          (+= ret (apply Result []
                         {"expr" expr-name "temp_vars" [expr-name
                                                        var]}))
          ret
          )))]

   [compile-expression
    (with-decorator (builds HyExpression)
      (fn [self expression]
        ;;; FIXME: macroexpand and "." and a lot more

        (setv fun (get expression 0))
        (setv func nil)
        (.compile-atom self fun expression)))]

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
         (+= result (mlast.Local [st-name]
                                 [result.force-expr]))))

      (+= result ld-name)
      result)]
   
   [compile-setv-expression
    (with-decorator (builds "setv")
      (fn [self expression]
        (let [[name (get expression 1)]
              [result (get expression 2)]]
          (setv result (.compile self result))
          (setv ld-name (.compile self name))
          ;; FIXME do we need this? (setv st-name (.-storeize self ld-name))
          (+= result (mlast.Set [ld-name.expr]
                                [result.force-expr]))
          result)))]

   [compile-integer
    (with-decorator (builds HyInteger)
      (fn [self number]
        (mlast.Number number)))]

   [compile-float
    (with-decorator (builds HyFloat)
      (fn [self number]
        (mlast.Number number)))]

   [compile-string
    (with-decorator (builds HyString)
      (fn [self string]
        (mlast.String string)))]

   [compile-symbol
    (with-decorator (builds HySymbol)
      (fn [self symbol]
        ;;; FIXME more complex case
        (mlast.Id (ast-str symbol))))]
   ])



