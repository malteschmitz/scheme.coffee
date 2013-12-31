###

scheme.coffee

A Scheme interpreter written in CoffeeScript.

Copyright (c) 2013 Malte Schmitz

This software is released under the MIT License.

###


# JavaScript help functions

hasOwnProp = (object, name) ->
  Object.prototype.hasOwnProperty.call(object, name)

isArray = Array.isArray or (x) ->
  Object.prototype.toString.call(x) == '[object Array]'

isNumber = (x) ->
  Object.prototype.toString.call(x) == '[object Number]'

isString = (x) ->
  Object.prototype.toString.call(x) == '[object String]'

isObject = (x) -> x == Object(x)

# Scheme interpreter

expressionToAction = (e) ->
  if isNumber(e) or isString(e)
    atomToAction(e)
  else
    listToAction(e)

primitiveFunctions = {}

atomToAction = (e) ->
  if isNumber(e) or e == '#t' or
      e == '#f' or primitiveFunctions[e]?
    constAction
  else
    identifierAction

listToAction = (e) ->
  if e.length > 0 and isString(e[0])
    if e[0] == 'quote'
      quoteAction
    else if e[0] == 'lambda'
      lambdaAction
    else if e[0] == 'cond'
      condAction
    else
      applicationAction
  else
    applicationAction

lookupInTable = (name, table) -> table[name]

baseTable = {}

initialTable = ->
  Object.create(baseTable)

updateTable = (t1, names, values) ->
  t = initialTable()
  for key of t1
    if hasOwnProp(t1, key)
      t[key] = t1[key]
  for i in [0..Math.min(names.length, values.length)-1]
    t[names[i]] = values[i]
  t
    
meaning = (e, table) -> expressionToAction(e)(e, table)

constAction = (e, table) ->
  if isNumber(e)
    e
  else if e == '#t'
    true
  else if e == '#f'
    false
  else
    ['primitive', e]

quoteAction = (e, table) ->
  if e.length == 2
    e[1]
  else
    throw "Wrong number of arguments for quote: #{e}."

identifierAction = (e, table) ->
  res = lookupInTable(e, table)
  if res?
    res
  else
    throw "Identifier #{e} not found in the current table."

# Stores the closure as array containing
# ['non-primitive', [table, formals, body]]
lambdaAction = (e, table) ->
  if e.length == 3
    ['non-primitive', [table].concat(e.slice(1))]
  else
    throw "Wrong number of arguments for lambda: #{e}"

condAction = (e, table) ->
  if e.length > 1
    for line in e.slice(1)
      if isArray(line) and line.length == 2
        if line[0] == 'else'
          return meaning(line[1], table)
        else if meaning(line[0], table)
          return meaning(line[1], table)
      else
        throw "Unable to interprete cond line #{line}."
  else
    throw "Not enough lines for cond: #{e}."
  
meaningList = (list, table) ->
  if isArray(list)
    for e in list
      meaning(e, table)
  else
    throw "Unable to interprete parameter list #{list}"

applicationAction = (e, table) ->
  if e.length >= 1
    apply(meaning(e[0], table), meaningList(e.slice(1), table))
  else
    throw 'Unable to handle empty list.'

apply = (fun, vals) ->
  if isArray(fun) and fun.length == 2
    if fun[0] == 'primitive'
      applyPrimitive(fun[1], vals)
    else if fun[0] == 'non-primitive'
      applyClosure(fun[1], vals)
    else
      throw "Unable to apply #{fun}"
  else
    throw "Unable to apply #{fun}"

applyPrimitive = (name, vals) ->
  if primitiveFunctions[name]?
    primitiveFunctions[name](vals)
  else
    throw "Unknown primitive #{name}."  

applyClosure = (closure, vals) ->
  if closure.length == 3 and
      isObject(closure[0]) and isArray(closure[1])
    meaning(closure[2],
      updateTable(closure[0], closure[1], vals))
  else
    throw "Unable to handle closure #{closure}."

# Scheme parser

parse = (text, offset) ->
  pos = offset or 0
  trimLeft = ->
    pos += 1 while /\s/.test(text.charAt(pos)) and pos < text.length
  token = ->
    start = pos
    pos += 1 while not /[\s()]/.test(text.charAt(pos)) and pos < text.length
    val = text.slice(start, pos)
    if /^[+-]?[0-9]+$/.test(val)
      +val
    else
      val
  list = ->
    pos += 1 # skip '('
    val = []
    while text.charAt(pos) != ')'
      val.push(expression())
      trimLeft()
    pos += 1 # skip ')'
    val
  expression = ->
    trimLeft()
    if text.charAt(pos) == '('
      list()
    else if text.charAt(pos) == ')'
      throw "Unmatched closing parenthesis."
    else
      token()
  if offset?
    exp = expression()
    trimLeft()
    [exp, pos]
  else
    expression()

# interface for parser and interpreter

definePrimitive = (name, fun) ->
  primitiveFunctions[name] = fun

define = (name, e) ->
  baseTable[name] = evaluate(e)

value = (e) -> meaning(e, initialTable())

evaluate = (e) -> value(parse(e))

# primitive functions

definePrimitive('eq?', (vals) ->
  if vals.length == 2 and
      primAtom([vals[0]]) and primAtom([vals[1]])
    vals[0] == vals[1]
  else
    throw 'Wrong arguments for eq?.')

definePrimitive('atom?', (vals) ->
  if vals.length == 1
    isNumber(vals[0]) or isString(vals[0]) or
      (isArray(vals[0]) and vals[0].length == 2 and
        (vals[0][0] == 'primitive' or
          vals[0][0] == 'non-primitive'))
  else
    throw 'Wrong number of arguments for atom?.')

definePrimitive('number?', (vals) ->
  if vals.length == 1
    isNumber(vals[0])
  else
    throw 'Wrong number of arguments for number?.')

definePrimitive('null?', (vals) ->
  if vals.length == 1 and isArray(vals[0])
    vals[0].length == 0
  else
    throw 'Wrong arguments for null?.')

definePrimitive('cons', (vals) ->
  if vals.length == 2 and isArray(vals[1])
     [vals[0]].concat(vals[1])
   else
     throw 'Wrong arguments for cons.')

definePrimitive('car', (vals) ->
  if vals.length == 1 and isArray(vals[0])
      vals[0][0]
    else
      throw 'Wrong arguments for car.')

definePrimitive('cdr', (vals) ->
  if vals.length == 1 and isArray(vals[0])
      vals[0].slice(1)
    else
      throw 'Wrong arguments for cdr.')

definePrimitive('+', (vals) ->
  if vals.length == 2 and isNumber(vals[0]) and
      isNumber(vals[1])
    vals[0] + vals[1]
  else
    throw 'Wrong arguments for +.')

definePrimitive('-', (vals) ->
  if vals.length == 2 and isNumber(vals[0]) and
      isNumber(vals[1])
    vals[0] - vals[1]
  else
    throw 'Wrong arguments for -.')

definePrimitive('*', (vals) ->
  if vals.length == 2 and isNumber(vals[0]) and
      isNumber(vals[1])
    vals[0] * vals[1]
  else
    throw 'Wrong arguments for *.')

definePrimitive('/', (vals) ->
  if vals.length == 2 and isNumber(vals[0]) and
      isNumber(vals[1])
    ~~(vals[0] / vals[1])
  else
    throw 'Wrong arguments for /.')

definePrimitive('<', (vals) ->
  if vals.length == 2 and
      isNumber(vals[0]) and isNumber(vals[1])
    vals[0] < vals[1]
  else throw 'Wrong arguments for <.')

# non-primitive functions

define('y', '
  (lambda (f)
    ((lambda (mk) (mk mk))
      (lambda (mk)
        (f (lambda (x) ((mk mk) x))))))')

define('if', '
  (lambda (q s1 s2)
    (cond
      (q s1)
      (else s2)))')

define('not', '
  (lambda (x) (if x #f #t))')

define('and', '
  (lambda (x y) (if x y #f))')

define('or', '
  (lambda (x y) (if x #t y))')

define('zero?', '
  (lambda (x) (eq? x 0))')

define('add1', '
  (lambda (x) (+ x 1))')

define('sub1', '
  (lambda (x) (- x 1))')

define('>=', '
  (lambda (x y) (not (< x y)))')

define('<=', '
  (lambda (x y) (or (< x y)
    (eq? x y)))')

define('>', '
  (lambda (x y) (not (<= x y)))')

# Using the scheme parser and interpreter on given file

do ->
  fs = require('fs')
  text = fs.readFileSync(process.argv[2], 'utf8')
  pos = 0
  while pos < text.length
    [expression, pos] = parse(text, pos)
    console.log(value(expression))
