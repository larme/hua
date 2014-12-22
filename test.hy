(def a (if true
         (do
          1
          3
          4)
         2))

(defclass Test [object]
  [[--init--
    (fn [self]
      (setv self.-x 42)
      nil)]
   [x (with-decorator property
        (defn x [self]
          self.-x))]

   [x (with-decorator x.setter
        (defn x [self value]
          (print "hi")
          (setv self._x value)))]])
