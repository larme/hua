(import [hy.models.string [HyString]])

(defmacro defsection [sect-name &rest body]
  (def sep (HyString "----------------------------"))
  (def end (HyString "------- section ends -------\n"))
  `(do
    (print ~sect-name)
    (print ~sep)
    (do ~@body)
    (print  ~end)))

