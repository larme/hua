(import [hua.core.utils [hua-gensym simple-form?]])

;;; compare operation with more than 2 arguments

(defn my-eq [a b]
  (= a b))

(defn my-lt [a b]
  (< a b))

;;; operators like =* (opstar) can only accept two arguments
;;; The macro below will generate macros like = (op), which will accept two or more arguments
(defmacro --def-hua-comp-op-- [op opstar]
  `(defmacro ~op [&rest exprs]
     (def op* (quote ~opstar))
     (when (my-lt (len exprs) 2)
       (macro-error exprs
                    "comparison operator needs at least 2 operands"))
     
     (if (my-eq (len exprs) 2)
       ;; if only two arguments are given, return the  normal form of opstar
       `(~op* ~(get exprs 0)
              ~(get exprs 1))

       ;; if more than two arguments are given, we will expand to the form of (and (opstar e1 e2) (opstar e2 e3) ...)
       ;; The problems is that expressions like e2 will be evaluated twice. We need temporary variables to hold the evaluated value of e2.
       (let [[temp-vars (list-comp (if (simple-form? expr)
                                     nil
                                     (hua-gensym))
                                   [expr exprs])]
             [binding-body (list-comp `(def ~(get temp-vars i) ~(get exprs i))
                                      [i (range (len exprs))]
                                      (not (nil? (get temp-vars i))))]
             [compare-vars (list-comp (if (simple-form? expr)
                                        expr
                                        (hua-gensym))
                                      [expr exprs])]
             [comparing-body (list-comp `(~op* ~(get compare-vars (- i 1))
                                               ~(get compare-vars i))
                                        [i (range 1 (len compare-vars))])]]
         `(do
           ~@binding-body
           (and ~@comparing-body))))))

(--def-hua-comp-op-- = =*)
(--def-hua-comp-op-- < <*)
(--def-hua-comp-op-- <= <=*)

(defmacro > [&rest exprs]
  `(not (<= ~@exprs)))

(defmacro >= [&rest exprs]
  `(not (< ~@exprs)))

(defmacro != [&rest exprs]
  `(not (= ~@exprs)))
