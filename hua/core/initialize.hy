(import os)
(import [hy.models.string [HyString]])

;;; In case the future lua release removes the unpack function entirely

(defmacro --hua-def-unpack-- []
  `(def unpack (or unpack table.unpack)))


;;; add the current path in the lua load path

(defmacro --hua-add-stdlib-path-- []
  (def this-path
    (HyString
     (os.path.dirname
      (os.path.realpath --file--))))
  `(setv package.path
         (string.format "%s;%s/?.lua"
                        package.path
                        ~this-path)))

;;; import standard library
(defmacro --hua-import-stdlib-- []
  `(hua-import [hua_stdlib [apply
                            dec
                            first
                            inc

                            ;; moses functions
                            clone
                            array?
                            table?
                            equal?
                            callable?
                            iterable?
                            string?
                            function?
                            nil?
                            number?
                            nan?
                            finite?
                            boolean?
                            int?]]))

;;; a macro to import all core macros

(defmacro --hua-init-macros-- []
  `(do
    (require-macro hua.core.macros)
    (require-macro hua.core.op)
    (require-macro hua.core.assignment)
    (require-macro hua.core.comp)
    (require-macro hua.core.oo)
    (require-macro hua.core.module)))


(defmacro --hua-initialize-- []
  `(do
    (--hua-add-stdlib-path--)
    (--hua-def-unpack--)
    (--hua-init-macros--)
    (--hua-import-stdlib--)))
