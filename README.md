# Hua

Hua (㕦) is a [hy](https://github.com/hylang/hy)-like lisp language to lua compiler. It utilizes hy's parser and macro expansion mechanism and compiles the parsed hy syntax tree to [metalua AST](https://github.com/fab13n/metalua/blob/master/doc/ast.txt). The result is then passed to a lua runtime (using the python/lua bridge [lupa](https://github.com/scoder/lupa)) and use [Typed Lua](https://github.com/andremm/typedlua)'s code generator to generate lua codes. Hua is a work in progress and should be considered pre-alpha quality code right now (though I have been using hua to write lua codes scripting [Max](https://cycling74.com/products/max/) for the past month and everything seems to be OK).

## Why?

The main benefit of hua over lua is the ability of meta-programming. Hua includes macros to do hy-style list and dict comprehension, a (still naive)  OO system and some other tiny neat features. Though currently [l2l](https://github.com/meric/l2l) and [moonlisp](https://github.com/leafo/moonlisp) may be more mature alternatives.

One of the benefit of hua over hy is speed, especially if you run the compiled lua code with [luajit](http://luajit.org). Hua (and lua) has a proper lexical scoping implementation. For example, nested `let` is broken in hy, while hua has full support of nested `let`. Lua is widely used to be embedded in host application so for many softwares lua is the only option to extend the softwares capability.

## Quickstart

1. Create and activate a virtualenv
2. Install [lupa](https://github.com/scoder/lupa). It's a little bit tricky on Mac. If you have any troubles, please refer to [this guide](https://gist.github.com/larme/9079789cdb1f2fb72b34). (Side notes: currently hua uses [Typed Lua](https://github.com/andremm/typedlua)'s ast->code compiler to generate lua codes so a lua runtime in python (i.e. lupa) is required. I plan to write a native compiler that compiles hua to lua so at least the compiling process doesn't require a lua runtime. However I also plan to add repl to hua which will need the lua runtime. Hence lupa will still be a dependancy in future if you want to use the repl.)
3. You need to install hua from the git repository: `git clone https://github.com/larme/hua.git; cd hua`
4. `pip install -e .`
5. Now you can try the compiler by cding into `eg/` and typing `huac example.hua`. The output will be `example.lua`.


## Brief Introduction aka Comparison with Hy

Read `example.hua` and its output to get a quick idea of how hua codes look like and what they produce.

Like hy is a lispy python, hua is a lispy lua. It follow the conventions of lua, which means though hua compiler try to act like hy as much as possible, some aspects are still different.

### hua macros are written in hy

Because currently hua is just a compiler and the compiler is written in hy, hua macros also need to written in hy.

### `require`, `require-macro` and `hua-import`

Because lua use `require` to import a module, we use `require-macro` to require macros from a hy file.

You can just use `require` to require lua modules, or you can use `hua-import`, which works like `import` in hy.

### `setv` vs. `def`

Because lua is not local by default, `setv` and `def`  have different meanings in hua (unlike in hy). `def` is used to introduce a local variable and give it an initial value.  `setv` will mutate a variable's value or introduce a global variable.

Frankly speaking I think in this way the code is more clear and readable. 

``` lisp
(def x 10)
(setv x 20)
```

is compiled to

``` 
local x = 10
x = 20
```

There's no way to declare a local variable without assigning an initial value to the variable (like `local x` in lua), just use `(def x nil)`. (Or we can introduce a new keyword `local` which works just like lua's `local`)

### Multiple Assignment / Returned Value

The multiple assignment in lua and python are quite different. Assuming a function `foo` return two value `1, 2`, then after `x, y = foo()`, `x` will be 1 and `y` will be 2 in both python and lua. However after the execution of the following codes:

``` 
x = foo()
```

In python `x` will have the value of a tuple `(1, 2)`, while in lua `x` will have the value 1.

Hua follows lua's behavior, sometimes it may cause unexpected problems. Considering the following codes:

``` lisp
(print
 (if true
   (foo) 
   (bar)))
```

You may think this expression will print out `1	2`. However due to the way how hua compiler works, it will actually print out `1`. The reason is that because the above hua code will be compiled  to the following lua code:

``` lua
local _hua_anon_var_1
if true then
  _hua_anon_var_1 = foo()
else
  _hua_anon_var_1 = bar()
end
print(_hua_anon_var_1)
```

To prevent this kinds of mistakes, you have to handle the multiple returned values explicitly. One way is to use multiple assignment to assign several variables to the returned values. You need to know how many returned values you will use in advance.

``` lisp
(setv (, x y)
      (if true
        (foo) 
        (bar)))
(print x y)
```

which will compile to:

``` lua
local _hua_anon_var_2, _hua_anon_var_3
if true then
  _hua_anon_var_2, _hua_anon_var_3 = foo()
else
  _hua_anon_var_2, _hua_anon_var_3 = bar()
end
x, y = _hua_anon_var_2, _hua_anon_var_3
print(x,y)
```

Another way is packing the multiple returned values into a table using `[(foo)]` syntax.

``` lisp
(print
 (unpack
  (if true
    [(foo)] 
    [(bar)])))
```

will compile to

``` lua
local _hua_anon_var_1
if true then
  _hua_anon_var_1 = {foo()}
else
  _hua_anon_var_1 = {bar()}
end
print(unpack(_hua_anon_var_1))
```



### `for` loop syntax

Lua has both generic for and numeric for. The generic for works similar to python's for. However because lua's table is not iterable itself, you need to call `pairs` or `ipairs` on the table. The following hua code:

``` lisp
(def t1 [3 4 5 6])
(def t2 {"one" 1 "two" 2})
(for [(, i v1) (ipairs t1)
      (, k v2) (pairs t2)]
  (print i v1 k v2))

```

will compiled to:

``` lua
local t1 = {3, 4, 5, 6}
local t2 = {two = 2, one = 1}
for i, v1 in ipairs(t1) do
  for k, v2 in pairs(t2) do
    print(i,v1,k,v2)
  end
end
```

Because you will always call functions like `pairs` and `iparis` on table in the `for` expression, I save the syntax `(for [x [i1 i2 i3]] ...)` for the numeric for statement in lua. Something like `(for [i [1 14 3]] (print i))` will compile to:

``` lua
for i = 1, 14, 3 do
  print(i)
end
```

You can mix numeric for and generic for in the same `for` expression. The following codes:

``` lisp
(for [i [1 3]
      key (pairs {"pos" 3 "cons" 2})]
  (print "mixed:" i key))
```

will compiles to:

``` lua
for i = 1, 3 do
  for key in pairs({pos = 3, cons = 2}) do
    print("mixed:",i,key)
  end
end
```



### List and Dict comprehensive

Hua's list and dict comprehensive are macros that expanded to `for` expressions. So the syntax is different to hy's but similar to hua's `for`

``` lisp
(def l (list-comp (* i value)
                  [i [1 10]
                   (, _ value) (pairs {"T" 1 "F" 0})]))
```

will compile to

``` lua
local l
do
  local _hua_result_1235 = {}
  for i = 1, 10 do
    for _, value in pairs({T = 1, F = 0}) do
      _hua_result_1235[(1 + #(_hua_result_1235))] = (i * value)
    end
  end
  l = _hua_result_1235
end
```



### Tail Call Optimization

Unlike python, lua has tail call optimization. However if you define some recursive functions like below, it may blow the stack:

``` lisp
(defn test-tco [n]
    (if (> n 1)
      (test-tco (- n 1))
      (print "May overflow here")))
```

The compiled lua code explained why:

``` lua
local test_tco = nil
test_tco = function (n)
  local _hua_anon_var_7
  if not (n <= 1) then
    _hua_anon_var_7 = test_tco((n - 1))
  else
    _hua_anon_var_7 = print("May overflow here")
  end
  return _hua_anon_var_7
end
```

Use `return` directly will solve this problem (at least for simple recursive form). 

``` lisp
(defn test-tco2 [n]
  (if (> n 1)
    (return (test-tco (- n 1)))
    (print "No overflow!")))
```

will compiles to:

``` lua
local test_tco2 = nil
test_tco2 = function (n)
  local _hua_anon_var_2
  if not (n <= 1) then
    return test_tco((n - 1))
  else
    _hua_anon_var_2 = print("No overflow!")
  end
  return _hua_anon_var_2
end
```

However please don't overuse `return`. If you want to return a table at the end of a file (as a module table), consider using `export` at the end 

### No Keyword Arguments for function

Because lua doesn't support named arguments, hua will not support keyword arguments.

### "dot call"s

In hy `(foo.bar "hello")` is the same as `(.bar foo "hello")`. They both invoke a method `bar` of object `foo` with a single parameter `"hello"`. However in hua it's entirely different. `(foo.bar "hello")` compiles to `foo.bar("hello")` while `(.bar foo "hello")` compiles to `foo:bar("hello")`. In both case `bar` is a property of table `foo`, however in the first case `bar` is called with a single argument `"hello"` while in the second case `bar` is called with two arguments: table `foo` and `"hello"`.

### `defclass` difference

`defclass` works like hy's one. Use `--init` instead of `--init--`. When defining a class without parent class, `--init` method is mandatory.

``` lisp
;; A class without parent class.
;; A --init method is required for class without parent class.
(defclass Animal []
  [[--init
    (fn [self steps-per-turn]
        (setv self.steps-per-turn steps-per-turn))]
   [move
    (fn [self]
        (print (concat "I moved "
                       (tostring self.steps-per-turn)
                       " steps!")))]])

;; Hua only support single inheritance.
;; Use `(super method paras...)' to call parent's method
(defclass Cat [Animal]
  [[--init
    (fn [self steps-per-turn sound]
        (super --init  steps-per-turn)
        (setv self.sound sound))]
   [move
    (fn [self]
        (print self.sound)
        (super move))]])
```



### Misc

Nearly any lua vs python differences will hold in hua vs hy. Some examples: hua has correct lexical scoping so nested `let` works; only `nil` and `false` are false in hua while empty string and list are also false in hy etc; hua table are not iterable like python's dict and list.

## To be Improved

By priority:

- No sane error messages, no error codes line numbers!
  
- No enough test cases yet!
  
  - A repl may be needed for some test cases.
  
- Currently every hua file need to begin with some initializing codes mainly to import standard macros into the hua file (see examples.hua). This should be done automatically.
  
- Currently every lua file output by hua compiler will add `hua/hua/core/` into lua's package path and auto require some functions in `hua/hua/core/hua_stdlib.lua`. The motif is that every lua file compiled by hua is usable immediately without any further configuration. However this is not a good idea because that means every lua file produced by hua compiler is not portable between machines. Later we may pack the `hua_stdlib.lua` as a luarock or ask users to copy the file to their lua package path.
  
- Talking about `hua_stdlib.lua`, we may add more functional list/dict manipulating functions using the excellent [Moses](https://github.com/Yonaba/Moses) library.
  
- ~~`huac` can only compile one file at one time.~~
  
- Repl, again
  
- Native compiler in hy.
  
- Docstring for function definition? It's quite doable because `defn/defun` is just a macro.








## Acknowledgements

Thanks the authors of [hy](https://github.com/hylang/hy), [lupa](https://github.com/scoder/lupa) and [Typed Lua](https://github.com/andremm/typedlua). They wrote the most crucial parts and I'm just glueing these parts together.