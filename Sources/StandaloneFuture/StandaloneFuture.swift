import Foundation
import Dispatch

fileprivate struct RunResult<T>
{
    let changed: Bool
    let value: T?

    init (changed: Bool, value: T? = nil)
    {
        self.changed = changed
        self.value = value
    }
}


private class CallbackList<T>
{
    fileprivate var isRunning: Bool
    fileprivate var current: Int
    fileprivate var callbacks: [(T?) -> T?]

    init () {
        isRunning = false;
        current = 0
        callbacks = []
    }

    fileprivate func add(function: @escaping (T?) -> T?)
    {
        callbacks.append(function)
    }

    fileprivate func run(value: T?) -> RunResult<T>
    {
        if (isRunning) { return RunResult<T>(changed: false) }
        isRunning = true
        var newValue = value
        for i in self.current...self.callbacks.count {
            newValue = self.callbacks[i](value)
        }
        self.isRunning = false
        return RunResult<T>(changed: true, value: newValue)
    }
}

// Promise

class Promise <T> {
    
    let futureResult: Future<T>

    init() {
        futureResult = Future<T>()
    }

    public func map(toFunc: @escaping (T?) -> T?)
    {
        futureResult.map(toFunc: toFunc)
    }

    public func succeed(result: T) {
        futureResult.value = result
        futureResult.initialValueReady = true
    }

    public func fail(error: Error) {
        futureResult.failure = true
    }

}


// Future

class Future<T> {

    fileprivate var callbackList: CallbackList<T>
    fileprivate var initialValueReady: Bool {
        didSet {
            self.run()
        }
    }

    public fileprivate(set) var ready: Bool
    public fileprivate(set) var value: T?
    public fileprivate(set) var failure: Bool {
        didSet {
            if failure == false { return }
            initialValueReady = true
            ready = true
            value = nil
        }
    }

    init()
    {
        ready = false
        value = nil
        initialValueReady = false
        failure = false
        callbackList = CallbackList<T>()
    }

    public func map(toFunc: @escaping (T?) -> T?)
    {
        callbackList.add(function: toFunc)
        run()
    }

    fileprivate func run()
    {
        if callbackList.isRunning || !initialValueReady || failure { return }

        ready = false

        DispatchQueue.global().async {
            let result =  self.callbackList.run(value: self.value)
            if result.changed {
                self.value = result.value
            }
            self.ready = true
        }
    }

}