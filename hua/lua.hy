(import [os.path [realpath dirname]])
(import lupa)
(import [lupa [LuaRuntime]])

(def current-path (dirname(realpath --file--)))

(defn init-lua []
  "return a lua runtime"
  (apply LuaRuntime [] {"unpack_returned_tuples true"}))

(def lua (init-lua))

(defn -dict? [o]
  "if o is an instance of dictionary"
  (instance? dict o))

(defn -lt? [o]
  "if o is an instance of list or tuple"
  (instance? (, list tuple) o))

(defn lt->dict [lt]
  "convert a list/tuple to lua table style dict (index start with 1)"
  (let [[r {}]]
    (for [(, i v) (enumerate lt)]
      (assoc r (inc i) v))
    r))

(defn -dict->ltable [lua-runtime d-]
  "recursively convert a python dictionary into lua table"
  (let [[r {}]
        [d (if (-lt? d-)
             (lt->dict d-)
             d-)]]
    (for [(, k v) (.items d)]
      (let [[new-v (cond
                    [(-dict? v) (-dict->ltable lua-runtime v)]
                    [(-lt? v) (-dict->ltable lua-runtime (lt->dict v))]
                    [true v])]]
        (assoc r k new-v)))
    (.table-from lua-runtime r)))


(def tlua (init-lua))
(let [[lua-package-table (.require tlua "package")]
      [lua-package-path (. lua-package-table path)]]
  (assoc lua-package-table
         "path"
         (+ lua-package-path
            ";"
            current-path
            "/?.lua")))

(def tlcode (.require tlua "tlcode"))

(defn tlast->src [ast-table]
  (tlcode.generate (.table-from tlua (-dict->ltable tlua ast-table))))
