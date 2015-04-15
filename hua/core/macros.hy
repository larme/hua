(import [hy.models.list [HyList]]
        [hy.models.symbol [HySymbol]])

(defmacro first [coll]
  `(get ~coll 1))

(defn for-helper [body]
  (defn for-helper* [args-iter]
    (try
     `(for* [~(next args-iter)
             ~(next args-iter)]
        ~(for-helper* args-iter))
     (catch [e StopIteration]
       `(progn ~@body)))))

(defmacro for [args &rest body]
  "shorthand for nested for loops:
  (for [x foo
        y bar]
    baz) ->
  (for* [x foo]
    (for* [y bar]
      baz))"
  (cond 
   [(odd? (len args))
    (macro-error args "`for' requires an even number of args.")]
   [(empty? body)
    (macro-error None "`for' requires a body to evaluate")]
   [(empty? args) `(do ~@body)]
   [(= (len args) 2)  `(for* [~@args] ~@body)]
   [true
    (do
     (def args-iter (iter args))
     ((for-helper body) args-iter))]))

(defmacro let [variables &rest body]
  "Execute `body` in the lexical context of `variables`"
  (def macroed-variables [])
  (if (not (isinstance variables HyList))
    (macro-error variables "let lexical context must be a list"))
  (for* [variable variables]
    (if (isinstance variable HyList)
      (do
       (if (!= (len variable) 2)
         (macro-error variable "let variable assignments must contain two items"))
       (.append macroed-variables `(def ~(get variable 0) ~(get variable 1))))
      (if (isinstance variable HySymbol)
        (.append macroed-variables `(def ~variable None))
        (macro-error variable "let lexical context element must be a list or symbol"))))
  `(do-block ~@macroed-variables
             ~@body))


(defmacro-alias [defn defun] [name lambda-list &rest body]
  "define a function `name` with signature `lambda-list` and body `body`"
  (if (not (= (type name) HySymbol))
    (macro-error name "defn/defun takes a name as first argument"))
  (if (not (isinstance lambda-list HyList))
    (macro-error name "defn/defun takes a parameter list as second argument"))
  `(def ~name (fn ~lambda-list ~@body)))

