## Regression test: receiving into a reused `dst` must release its previous
## value: `recv`/`tryRecv` overwrite `dst` with the received message, and the
## old contents must be destroyed (their finalizers must run), not silently
## dropped.
##
## The destructions are counted with a destructor on the payload type, which
## is deterministic and independent of the GC (works under arc and orc alike).

discard """
  matrix: "--threads:on --gc:orc; --threads:on --gc:arc"
"""
import threading/channels
import std/isolation

type Item = object
  id: int

var destroyedCount = 0
proc `=destroy`(i: var Item) =
  if i.id != 0:
    inc(destroyedCount)

const N = 10_000

block recv:
  var (s, r) = newChan[Item]()
  var v: Item
  for i in 1..N:
    doAssert s.send(isolate(Item(id: i)))
    doAssert r.recv(v)
    doAssert v.id == i
  # Every overwrite of a live `v` destroyed the previous item (the first
  # overwrite replaced the default value, which is not counted).
  doAssert destroyedCount == N - 1, $destroyedCount & " " & $N

block tryRecv:
  # The `v` of the previous block was destroyed at the end of the block.
  doAssert destroyedCount == N, $destroyedCount & " " & $N
  var (s, r) = newChan[Item]()
  var v = Item(id: 42)
  # A failed tryRecv must leave `dst` untouched (in particular, not destroy it).
  doAssert not r.tryRecv(v)
  doAssert v.id == 42
  doAssert destroyedCount == N, $destroyedCount & " " & $N
  for i in 1..N:
    doAssert s.send(isolate(Item(id: i)))
    doAssert r.tryRecv(v)
    doAssert v.id == i
  doAssert destroyedCount == 2 * N, $destroyedCount & " " & $N

# Plus the scope-end destruction of the live `v` of this block (item N):
# the total is 2N + 1.
doAssert destroyedCount == 2 * N + 1, $destroyedCount & " " & $N
