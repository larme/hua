;; (def a (if true
;;          (do
;;           1
;;           3
;;           4)
;;          2))

;; (defclass Test [object]
;;   [[--init--
;;     (fn [self]
;;       (setv self.-x 42)
;;       nil)]
;;    [x (with-decorator property
;;         (defn x [self]
;;           self.-x))]

;;    [x (with-decorator x.setter
;;         (defn x [self value]
;;           (print "hi")
;;           (setv self._x value)))]])

(import [hy.importer [import-file-to-hst]])
(import [compiler [HuaASTCompiler]])
(import [lua [mlast->src]])

(def result (let [[hst (import-file-to-hst "test.hua")]
                  [compiler (HuaASTCompiler "test")]]
              (print hst)
              (.compile compiler hst)))
                                ;(print "test results: " result)
                                ;(print "test results stmts: " (. result stmts [0] __dict__))
                                ;(print "test results expr: " result.expr)
                                ;(print "haha: " (.to-table (. result stmts [0])))
(setv stmts (list-comp (.to-table stmt) [stmt result.stmts]))
(print (mlast->src stmts))


