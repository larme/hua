(import [hy.models.symbol [HySymbol]])

(defn hua-gensym [&optional [sym nil]]
  (def temp-sym (string (if sym
                          (gensym sym)
                          (gensym))))
  (HySymbol (.replace temp-sym ":" "_hua_")))
