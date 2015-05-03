(import argparse)
(import sys)

(import [hua.compiler [compile-file]])

(defn huac-main []

  (def options {"prog" "huac" "usage" "%(prog)s [options] FILE"})
  (def parser (apply argparse.ArgumentParser [] options))
  (apply .add-argument
         [parser "args"]
         {"nargs" argparse.REMAINDER "help" argparse.SUPPRESS})
  

  (setv options (.parse-args parser (slice sys.argv 1)))

  (for [filename options.args]
    (compile-file filename)))
