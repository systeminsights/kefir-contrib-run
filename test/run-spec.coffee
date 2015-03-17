K = require 'kefir'
{Some, None} = require 'fantasy-options'
{Left, Right} = require 'fantasy-eithers'
{head, last, runLog, runLogValues} = require '../src/run'

describe "head", ->
  abc = -> K.sequentially(10, ["A", "B", "C"])

  it "should resolve the promise with the first value", ->
    expect(head(abc())).to.become(Some("A"))

  it "should reject the promise with the first error", ->
    expect(head(abc().valuesToErrors())).to.be.rejected.and.become("A")

  it "should resolve the promise with None when nothing emitted", ->
    expect(head(K.never())).to.become(None)

  it "should reject promise when only error", ->
    expect(head(K.constantError("E"))).to.be.rejected

describe "last", ->
  abc = -> K.sequentially(10, ["A", "B", "C"])

  it "should resolve the promise with the last value", ->
    expect(last(abc())).to.become(Some("C"))

  it "should reject the promise with the first error", ->
    s = -> K.concat([abc(), K.constantError("E"), abc()])
    expect(last(s())).to.be.rejected.and.become("E")

  it "should resolve the promise with None when nothing emitted", ->
    expect(last(K.never())).to.become(None)

  it "should reject promise when only error", ->
    expect(head(K.constantError("E"))).to.be.rejected

describe "runLog", ->
  it "should return a promise that resolves with an array of all emitted errors and values", ->
    s1 = K.sequentially(10, [1, 2, 3])
    e1 = K.constantError("E1")
    s2 = K.sequentially(10, [44, 55])
    e2 = K.constantError("E2")
    stream = K.concat([s1, e1, s2, e2])

    expect(runLog(stream)).to.become([
      Right(1),
      Right(2),
      Right(3),
      Left("E1"),
      Right(44),
      Right(55),
      Left("E2")
    ])

  it "should resolve with an empty array when stream never emits", ->
    expect(runLog(K.never())).to.eventually.beEmpty

