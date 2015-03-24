(import [hua.core.utils [hua-gensym simple-form?]])

(defmacro assoc [table &rest indexes-and-value]
  (def last-index (dec (len indexes-and-value)))
  (def indexes (slice indexes-and-value
                      0
                      last-index))
  (def value (get indexes-and-value last-index))
  `(setv (get ~table ~@indexes) ~value))

(defmacro --hua-augmented-assignment-- [op op-assign]
  `(defmacro ~op-assign [target val]
     (def op-symbol (quote ~op))
     (if (simple-form? target)
       `(setv ~target (~op-symbol ~target ~val))
       (macro-error target
                    "Sorry, currently the first argument of augmented assignment can be only a symbol"))))

(--hua-augmented-assignment-- + +=)
(--hua-augmented-assignment-- - -=)
(--hua-augmented-assignment-- * *=)
(--hua-augmented-assignment-- / /=)
