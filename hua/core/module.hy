(import [hy.models.list [HyList]]
        [hy.models.symbol [HySymbol]]
        [hua.core.utils [hua-gensym]])

(defn import-helper [item]
  (when (not (instance? (, HySymbol HyList) item))
    (macro-error item "(import) requires a Symbol or a List"))

  (if (instance? HySymbol item)
    `(require ~(string item))
    (cond [(= 2 (len item))
           (let [[module (get item 0)]
                 [syms (get item 1)]
                 [declares (list-comp `(def ~sym nil)
                                      [sym syms])]
                 [bindings (list-comp
                            `(setv ~sym
                                   (get --hua-import-m--
                                        ~(string sym)))
                            [sym syms])]]
             `(do
               ~@declares
               (let [[--hua-import-m-- (require ~(string module))]]
                 ~@bindings)))]
          [(and (= 3 (len item))
                (is (get item 1) :as))
           (let [[module (get item 0)]
                 [alias (get item 2)]]
             `(def ~alias (require ~(string module))))]
          [true
           (macro-error item
                        "When the argument of (import) is a List, it need to be in one of the two following form: 1. [module [var1 var2 ...]] or 2. [module :as alias]")])))

;;; well, before we have a way to name it import
(defmacro hua-import [&rest items]
  (def body (list-comp (import-helper item) [item items]))
  `(do ~@body))


;;; export a list o variables, use at the end of a hua file
(defmacro export [&rest vars]
  (def module-var (hua-gensym "module"))
  (def assignments (list-comp `(assoc ~module-var
                                      ~(string var)
                                      ~var)
                              [var vars]))
  `(let [[~module-var {}]]
     (do ~@assignments)
     (return ~module-var)))
