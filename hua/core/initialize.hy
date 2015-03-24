;;; a macro to import all core macros

(defmacro --hua-init-macros-- []
  `(do
    (require-macro hua.core.macros)
    (require-macro hua.core.op)
    (require-macro hua.core.assignment)
    (require-macro hua.core.oo)))
