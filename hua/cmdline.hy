(import argparse)
(import sys)
(import os.path)

(import [hy.importer [import-file-to-hst]])
(import [hua.compiler [HuaASTCompiler]])
(import [hua.mlast [to-ml-table]])
(import [hua.lua [tlast->src]])

(defn huac-main []

  (def options {"prog" "huac" "usage" "%(prog)s [options] FILE"})
  (def parser (apply argparse.ArgumentParser [] options))
  (apply .add-argument
         [parser "args"]
         {"nargs" argparse.REMAINDER "help" argparse.SUPPRESS})
  

  (setv options (.parse-args parser (slice sys.argv 1)))

  (def filename (get options.args 0))
  (def result-ast (let [[hst (import-file-to-hst filename)]
                        [compiler (HuaASTCompiler "FIXME")]]
                    (.compile compiler hst)))

  ;; FIXME
  (def stmts (to-ml-table result-ast.stmts))
  (def result (tlast->src stmts))
  (def (, basename extname) (os.path.splitext filename))
  (def lua-filename (+ basename ".lua"))
  (with [[lua-f (open lua-filename "w")]]
        (.write lua-f result)))
