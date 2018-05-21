import Darwin

/// A simple wrapper around `pthread_mutex_t`.
class Mutex {
    var mutex = pthread_mutex_t()
    
    /// Initalizes the mutex with its default values.
    init() {
        guard pthread_mutex_init(&mutex, nil) == 0 else {
            preconditionFailure()
        }
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    func tryLock() -> Bool {
        return pthread_mutex_trylock(&mutex) == 0
    }
}
