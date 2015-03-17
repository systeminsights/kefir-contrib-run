B = require 'bluebird'
R = require 'ramda'
{Some, None} = require 'fantasy-options'
{toArray} = require 'fantasy-contrib-either'
{attempt} = require 'kefir-contrib-fantasy'

# :: Kefir e a -> Promise e (Option a)
#
# Return the first value or error from an observable as a promise. If the
# observable ends without emitting an error or value, the promise will be
# resolved with Option.None.
#
head = (obs) ->
  last(obs.take(1))

# :: Kefir e a -> Promise e (Option a)
#
# Return the last value or first error from an observable as a promise. If the
# observable ends without emitting an error or value, the promise will be
# resolved with Option.None.
#
last = (obs) ->
  # NB: The stream is consumed inside a then() call to ensure it happens
  #     asynchronously as, if the observable has a current value or error,
  #     it invokes on* callbacks synchronously.
  B.resolve(obs.reduce(((_, v) -> Some(v)), None).endOnError())
    .then((obs1) ->
      new B((res, rej) ->
        done = false
        obs1.onError(rej).onValue(res).onEnd(-> res(None) unless done)))

# :: Kefir e a -> Promise _ [Either e a]
#
# Consumes an observable until it ends, returns a promise which will resolve
# with all emitted values and errors.
#
runLog = (obs) ->
  new B((resolve, reject) ->
    attempt(obs)
      .reduce(R.appendTo, [])
      .onValue(resolve)
      .onError(reject))

# :: Kefir e a -> Promise [e]
#
# Consumes an observable until it ends, returns a promise which will resolve
# with all emitted errors.
#
runLogErrors = (obs) ->
  runLog(obs) .then R.chain((ea) -> toArray(ea.swap()))

# :: Kefir e a -> Promise [a]
#
# Consumes a kefir stream until it ends, returns a promise which will resolve
# with all emitted values.
#
runLogValues = (obs) ->
  runLog(obs) .then R.chain(toArray)

module.exports = {
  head,
  last,
  runLog,
  runLogErrors,
  runLogValues
}

