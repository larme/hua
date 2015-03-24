(import [hy.models.list [HyList]])

(defmacro super [method &rest body]
  `((get --hua-parent-- ~(string method)) self ~@body))

(defmacro defclass [class-name base-list body]
  (when (not (instance? HyList base-list))
    (macro-error base-list "defclass's second argument should be a list"))
  (def parent-name
    (if (empty? base-list)
      nil
      (first base-list)))

  (def class-name-string (string class-name))

  ;; (try
  ;;  (def body-expression (iter body))
  ;;  (catch [e TypeError]
  ;;    (macro-error body
  ;;                 "Wrong argument type for defclass attributes definition.")))

  (def body-expression (iter body))

  (def arglist {})

  (for [b body-expression]
    (when (!= 2 (len b))
      (macro-error body-expression
                   "Wrong number of argument in defclass attribute."))
    (assoc arglist (string (first b)) (second b)))

  (def class-index-expr
    (if parent-name
      '(fn [cls name]
         (def val (rawget --hua-base-- name))
         (if (= val nil)
           (get --hua-parent-- name)
           val))
      '--hua-base--))

  `(do
    (def ~class-name nil)
    (do-block
     (def --hua-parent-- ~parent-name)
     (def --hua-base-- ~arglist)
     (def --hua-class-string-- ~class-name-string)
     (setv --hua-base--.--index --hua-base--)
     (when --hua-parent--
       (setmetatable --hua-base-- --hua-parent--.--base))
     (defn --hua-cls-call-- [cls *dotdotdot*]
       (def --hua-self-- (setmetatable {} --hua-base--))
       (.--init --hua-self-- *dotdotdot*)
       --hua-self--)
     (def --hua-class--
       (setmetatable {"__base" --hua-base-- "__name" --hua-class-string-- "__parent" --hua-parent--}
                     
                     {"__index" ~class-index-expr "__call" --hua-cls-call--}))
     (setv --hua-base--.--class --hua-class--)
     (when (and --hua-parent--
                --hua-parent--.--inherited)
       (--hua-parent--.--inherited --hua-parent-- --hua-class--))
     (setv ~class-name --hua-class--))))
