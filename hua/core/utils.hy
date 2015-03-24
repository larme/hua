(import [hy.models.symbol [HySymbol]])

(defn hua-gensym [&optional [sym nil]]
  (def temp-sym (string (if sym
                          (gensym sym)
                          (gensym))))
  (HySymbol (.replace temp-sym ":" "_hua_")))

;;; if a form is a string, a number or a symbol
(defn simple-form? [o]
  (or (string? o)
      (numeric? o)
      (instance? HySymbol o)))
