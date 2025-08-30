import Foundation

func getAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer) -> T? {
    if #available(iOS 14.0, *) {
        return objc_getAssociatedObject(object, key) as? T
    } else {
        return objc_getAssociatedObject(object, key) as AnyObject as? T
    }
}

func setAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer, _ value: T?) {
    objc_setAssociatedObject(object, key, value,.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
