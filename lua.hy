(import [os.path [realpath dirname]])
(import lupa)
(import [lupa [LuaRuntime]])

(def current-path (dirname(realpath --file--)))

(defn init-lua []
  "return a lua runtime"
  (apply LuaRuntime [] {"unpack_returned_tuples true"}))

(def lua (init-lua))

(let [[lua-package-table (.require lua "package")]
      [lua-package-path (. lua-package-table path)]]
  (assoc lua-package-table
         "path"
         (+ lua-package-path
            ";"
            (+ current-path
               "/metalua/?.lua"))))

(print (-> lua
           (.require "package")
           (. path)))

(def lua_astc (.new (.require lua "metalua.compiler")))

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

(defn -dict->ltable [lua-runtime d]
  "recursively convert a python dictionary into lua table"
  (let [[r {}]]
    (for [(, k v) (.items d)]
      (let [[new-v (cond
                    [(-dict? v) (-dict->ltable lua-runtime v)]
                    [(-lt? v) (-dict->ltable lua-runtime (lt->dict v))]
                    [true v])]]
        (assoc r k new-v)))
    (.table-from lua-runtime r)))

(def ast-sample1 {})

(let [[idents {1 {"tag" "Id" 1 "love"}
               2 {"tag" "Id" 1 "hate"}}]
      [values {1 {"tag" "Number" 1 134.5}
               2 {"tag" "Number" 1 3}}]]
  (setv ast-sample1 {"tag" "Local" 1 idents 2 values})
  (print (.ast-to-src lua-astc lua-astc (.table-from lua
                                                     (-dict->ltable lua ast-sample1)))))

(let [[ast-sample3 {"tag" "Call" 1 {"tag" "Id" 1 "love"} 2 {"tag" "Number" 1 3} 3 {"tag" "Number" 1 1.3}}]]
  (print (.ast-to-src lua-astc lua-astc (.table-from lua
                                                     (-dict->ltable lua ast-sample3)))))

(let [[ast-sample4 {"tag" "Invoke" 1 {"tag" "Id" 1 "love"} 2 {"tag" "String" "hello"} 3 {"tag" "Number" 1 1.3}}]]
  (print (.ast-to-src lua-astc lua-astc (.table-from lua
                                                     (-dict->ltable lua ast-sample4)))))

(def ast-sample2 {"tag" "Number" 1 3})
(print ast-sample1)

