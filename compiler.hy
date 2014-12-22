(import mlast)

(def -compile-table {})

(defn ast-str (s)
  (% "hua_%s" s))

(defn builds [-type]
  "assoc decorated function to compile-table"
  (lambda [f]
    (assoc -compile-table -type f)
    f))

(defclass Result [object]
  [[--init--
    (fn [self &rest args &kwargs kwargs]
      (setv self.stmts [])
      (setv temp-vars [])
      (setv -expr nil)
      (setv --used-expr false)

      (for [kwarg kwargs]
        (unless (in kwarg ["stmts"
                           "expr"
                           "temp-vars"])
          (print "something wrong"))
        (setattr self kwarg (get kwargs kwarg)))

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
      (if (and self.expr
               (not (instance? self.expr mlast.Id))
               (not (empty? self.stmts)))
        ;; FIXME?
        (+ (Result) self.expr)
        (Result)))]

   [rename
    (fn [self new-name-]
      "Rename the Result's temporary variables to a `new-name`"
      (let [[new-name (ast-str new-name-)]]
        (for [var temp-vars]
          (if (instance? var mlast.Id)
            (setv var.nodes [new-name])
            ;; FIXME
            "nothing"))
        (setv self.temp-vars [])))]

   [--add--
    (fn [self other]
      (cond
       [(instance? other mlast.Stat)
        (+ self (apply Result [] {stmts [other]}))]
       [(instance? other mlast.Expr)
        (+ self (apply Result [] {expr other}))]

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
    (for [result (slice result -1)]
      (+= ret result))
    ret))

;;; FIXME: checkargs

(defclass HuaASTCompiler [object]
  [[--init--
    (fn [self module-name]
      (setv self.anon-fn-count 0)
      (setv self.anon-var-count 0)
      (setv self.module-name module-name))]

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
      (when (in atom-type -compile-table)
        (let [[compile-f (get -compile-table atom-type)]
              [ret (compile-f self atom)]]
          (if (instance? ret Result)
            ret
            (+ (Result) ret)))))]

   [compile
    (fn [self tree]
      ;;; FIXME compiler errors
      (let [[-type (type tree)]]
        (compile-atom self -type tree)))]

   [-compile-collect
    (fn [self exprs]
      "Collect the expression contexts from a list of compiled expression."
      (let [[compiled-exprs []
             ret (Result)]]
        (for [expr exprs]
          (+= ret (.compile self expr))
          (.append compiled-exprs (ret.force_expr)))
        (, compiled-exprs ret)))]

   [-compile-branch
    (fn [self exprs]
      (-branch (list-comp (.compile self expr) [expr exprs])))]

   ;;; FIXME parse lambda list

   ;;; FIXME _storeize

   [compile-raw-list
    (with-decorator (builds list)
      (fn [self entires]
        (let [[ret (.-compile-branch self entries)]]
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
              [ret condition]]
          (if-not (and (empty? body.stmts)
                       (empty? orel.stmts))
                  (let [[var-name (.get-anon-fn self)]
                        [var (mlast.Id var-name)]]
                    "FIXME store value here"))
          )))]
   ])



