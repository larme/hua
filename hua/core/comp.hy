(import [hua.core.utils [hua-gensym]])

(defmacro list-comp [expr gen &optional condition]
  (def temp-var-l (hua-gensym "result"))
  (def result-assignment
    `(assoc ~temp-var-l
            (+ 1 (len ~temp-var-l))
            ~expr))
  (def for-body (if condition
                  `(when ~condition
                     ~result-assignment)
                  `(do
                    ~result-assignment)))
  `(let [[~temp-var-l []]]
     (for ~gen
       ~for-body)
     ~temp-var-l))

(defmacro dict-comp [key-expr value-expr gen &optional condition]
  (def temp-var-l (hua-gensym "result"))
  (def result-assignment
    `(assoc ~temp-var-l
            ~key-expr
            ~value-expr))
  (def for-body (if condition
                  `(when ~condition
                     ~result-assignment)
                  `(do
                    ~result-assignment)))
  `(let [[~temp-var-l []]]
     (for ~gen
       ~for-body)
     ~temp-var-l))
