###
# Essential.js 1.1.12
# @author Cedric Ruiz
# @license MIT
###

# Core
#
_ = {}
id = (x) -> x
K = (x) -> -> x
builtin = id.bind.bind id.call
toArray = builtin Array::slice
variadic = (as...) -> as

ncurry = (n, f, as=[]) -> (bs...) ->
  bs = as.concat bs
  if bs.length < n then ncurry n, f, bs else f bs...

λ = curry = (f) -> (as...) ->
  if f.length > as.length then ncurry f.length, f, as else f as...

apply = λ (f, as) -> f as...
applyNew = λ (f, as) -> new (f.bind [null, as...]...)

partial = (f, as...) -> (bs...) ->
  args = as.concat bs
  i = args.length
  while i--
    if args[i] is _
      args[i] = args.splice(-1)[0]
  f args...

flip = λ (f, x, y) -> f y, x
flip3 = λ (f, x, y, z) -> f z, y, x
nflip = (f) -> (as...) -> f as.reverse()...

compose = (fs...) -> fs.reduce (f, g) -> (as...) -> f g as...
pcompose = (fs...) -> (xs) -> xs.map (x, i) -> fs[i]? x
sequence = nflip compose

over = λ (f, g, x, y) -> f g(x), g y

notF = (f) -> (as...) -> not f as...
eq = λ (x, y) -> y is x
notEq = λ (x, y) -> y isnt x

typeOf = (x) -> Object::toString.call(x).slice 8, -1
isType = λ (t, x) -> typeOf(x) is t

toObject = (xs) ->
  xs.reduce (acc, x, i) ->
    acc[xs[i-1]] = x if i % 2
    acc
  ,{}

extend = (a, bs...) ->
  for b in bs
    for own k, v of b
      a[k] = v
  a

deepExtend = (a, bs...) ->
  for b in bs
    for own k, v of b
      a[k] = if typeof v is 'object'
        deepExtend a[k], v
      else
        v
  a

deepClone = (obj) ->
  init = if isType 'Array', obj then [] else {}
  Object.keys(obj).reduce (acc, k) ->
    x = obj[k]
    mustClone = isType('Array', x) or isType 'Object', x
    acc[k] = if mustClone then deepClone x else x
    acc
  ,init

forOwn = λ (acc, f, obj) ->
  Object.keys(obj).forEach (k, i) -> acc = f acc, k, obj[k], i
  acc

fold = flip3 builtin Array::reduce
fold1 = λ (f, xs) -> fold xs[0], f, xs
foldr = flip3 builtin Array::reduceRight
foldr1 = λ (f, xs) -> foldr xs[0], f, xs
map = flip builtin Array::map
filter = flip builtin Array::filter
any = flip builtin Array::some
all = flip builtin Array::every
each = flip builtin Array::forEach
indexOf = flip builtin Array::indexOf
concat = builtin Array::concat

slice = λ (i, j, xs) -> if j? then xs[i...j] else xs[i..]

first = ([x, xs...]) -> x
last = ([xs..., x]) -> x
rest = slice 1, null
initial = slice 0, -1
take = slice 0
drop = partial slice, _, null, _

inArray = λ (xs, x) -> x in xs

uniqueBy = λ (f, xs) ->
  seen = []
  xs.filter (x) ->
    fx = f x
    return true unless fx?
    return if fx in seen
    seen.push fx
    true

unique = uniqueBy id

dups = (xs) -> xs.filter (x, i) -> xs.indexOf(x) isnt i

flatten = (xs) ->
  while xs.some Array.isArray
    xs = Array::concat xs...
  xs

union = compose unique, flatten, variadic
intersection = compose unique, dups, flatten, variadic

flatMap = flip compose flatten, map

pluck = λ (x, xs) ->
  String(x).split('.').reduce (acc, x) ->
    return unless acc?
    acc[x]
  ,xs

rpluck = λ (x, xs) ->
  out = []
  while xs = pluck x, xs
    out.push xs
  out

where = λ (obj, xs) ->
  xs.filter (x) ->
    Object.keys(obj).every (k) -> obj[k] is x[k]

values = (obj) -> (v for own _, v of obj)
pairs = forOwn [], (acc, k, v) -> acc.concat [[k, v]]

zip = (xss...) -> xss[0].map (_, i) -> xss.map pluck i
zipWith = (f, xss...) -> apply(zip, xss).map partial apply, f

zipObject = compose toObject, flatten, zip

unzipObject = forOwn [[],[]], (acc, k, v, i) ->
  acc[0][i] = k ; acc[1][i] = v
  acc

range = λ (m, n) -> [m..n]

shuffle = (xs) ->
  ys = xs[..]
  for _, i in ys
    j = Math.random() * (i + 1) |0
    [ys[i], ys[j]] = [ys[j], ys[i]]
  ys

sortBy = λ (f, xs) ->
  xs.sort (x, y) ->
    fx = f x
    fy = f y
    switch
      when typeof fx is 'number' then fx - fy
      when fx > fy then 1
      when fx < fy then -1
      else 0

groupBy = λ (f, xs) ->
  xs.reduce (acc, x) ->
    fx = f x
    acc[fx] = (acc[fx] or []).concat [x]
    acc
  ,{}

countBy = sequence groupBy, forOwn {}, (acc, k, v) ->
  acc[k] = v.length
  acc

format = λ (xs, x) ->
  x.replace /%(\d+)/g, (_, i) -> xs[--i] or ''

template = λ (obj, x) ->
  x.replace /#\{(.+?)\}/g, (_, k) -> obj[k] or ''

gmatch = λ (re, x) ->
  out = []
  x.replace re, (as...) -> out.push.apply out, as[1...-2]
  out

# Fantasy
#
fmap = λ (f, ma) -> ma.map f
ap = λ (mf, ma) -> ma.ap mf
chain = λ (f, ma) -> ma.chain f

liftA = λ (ctor, f, ms) ->
  ms.reduce(
    (acc, ma) -> acc.ap ma
    ctor.of f
  )

seqM = λ (ctor, ms) ->
  ms.reduceRight(
    (ma, mb) ->
      ma.chain (a) ->
        mb.map (b) ->
          [b].concat a
    ctor.of []
  )

# Exports
#
module.exports = {
  # Core
  _, id, K,
  builtin, toArray,
  variadic, apply, applyNew,
  ncurry, λ, curry, partial,
  flip, flip3, nflip,
  compose, pcompose, sequence, over,
  notF, not:notF, eq, notEq, typeOf, isType,
  toObject, extend, deepExtend, deepClone, forOwn,
  fold, fold1, foldr, foldr1, map, filter, any, all, each, indexOf, concat,
  slice, first, last, rest, initial, take, drop,
  inArray, uniqueBy, unique, dups, flatten, union, intersection, flatMap,
  pluck, rpluck, where,
  values, pairs, zip, zipWith, zipObject, unzipObject,
  range, shuffle,
  sortBy, groupBy, countBy,
  format, template, gmatch,
  # Fantasy
  fmap, ap, chain, liftA, seqM
}

module.exports.expose = partial extend, _, module.exports
