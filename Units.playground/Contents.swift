//: Playground - noun: a place where people can play

import Cocoa

//: # Basics
protocol MathGroup {
	func +(a: Self, b: Self) -> Self
	func -(a: Self, b: Self) -> Self
	prefix func -(value: Self) -> Self
}

protocol MathBody {
	func *(a: Self, b: Self) -> Self
	func /(a: Self, b: Self) -> Self
}

protocol Numeric: MathGroup, MathBody {}

protocol Factor: FloatLiteralConvertible, IntegerLiteralConvertible {
	typealias Group: MathGroup

	func *(value: Group, factor: Self) -> Group
	func *(factor: Self, value: Group) -> Group
	func /(value: Group, factor: Self) -> Group
}

extension Double: Numeric, Factor {
	typealias Group = Double
}

//: ## typealias: Severe shortcomings
typealias Kelvin = Float

let boilingWaterTemp: Kelvin = 373.15

extension Kelvin {
	func toCelsius() -> Float {
		return self - 273.15
	}
}

let float: Float = -10
let r = float.toCelsius() + boilingWaterTemp
//: This works, but it should raise at least trigger a warning

//: ## Next try: tuples?
typealias Newton = (force: Float, unit: ())

func +(f0: Newton, f1: Newton) -> Newton {
	return (force: f0.force + f1.force, unit: ())
}

//: To bad, no extensions possible...
//extension Newton {}

let force = Newton(force: 1, unit: ())

//: But you can do calculations
print(force + force)

//: ## Enums?
/*:
My first idea was to concentrate on the basic units, and build a system on the basis of them
*/
enum SIUnit<Number: MathGroup> {
	case mass(kg: Number)
	case Temperature(kelvin: Number)
	case Time(seconds: Number)
}
//: But that didn't work out well, so I discarded this approach

//: ## Enums, but different
//: This is my favority - but it needs a sound foundation
protocol Quantity: MathGroup {
	typealias NumberType: MathGroup // Our values have to be stored somehow

	// To have several units that are compatible with each other, we need conversion
	func toBaseUnit() -> NumberType
	static func fromBaseUnit(value: NumberType) -> Self
}

//: With the conversion in place, we can define our operations
func +<T: Quantity>(value0: T, value1: T) -> T {
	return T.fromBaseUnit(value0.toBaseUnit() + value1.toBaseUnit())
}
func -<T: Quantity>(value0: T, value1: T) -> T {
	return T.fromBaseUnit(value0.toBaseUnit() - value1.toBaseUnit())
}
prefix func -<T: Quantity>(value: T) -> T {
	return T.fromBaseUnit(-value.toBaseUnit())
}

//: Sadly, the following does not compile...
//func *<F: Factor, T: Quantity where F.Group == Quantity.NumberType>(factor: F, quantity: T) -> T {
//	return T.fromBaseUnit(factor * quantity.toBaseUnit())
//}

//: But this workaround is enough for my little example
func *<F: Factor, T: Quantity where T.NumberType == Double, F.Group == Double>(factor: F, quantity: T) -> T {
	return T.fromBaseUnit(factor * quantity.toBaseUnit())
}
func *<F: Factor, T: Quantity where T.NumberType == Double, F.Group == Double>(quantity: T, factor: F) -> T {
	return T.fromBaseUnit(factor * quantity.toBaseUnit())
}
func /<F: Factor, T: Quantity where T.NumberType == Double, F.Group == Double>(quantity: T, factor: F) -> T {
	return T.fromBaseUnit(quantity.toBaseUnit() / factor)
}

//: ### May the force be with you ;-) - first example
/*:
Double is nice, but maybe we want to use Floats - or even vectors - to express a quantity.
Generics can help us here.
*/
enum GenericForce<T: MathGroup, F: Factor where F.Group == T>: Quantity {
	typealias NumberType = T

	case Newton(NumberType)
	case Kilopound(NumberType)

	func toBaseUnit() -> NumberType {
		switch self {
		case .Newton(let value): return value
		case .Kilopound(let value): return (4448.221615255 as F) * value
		}
	}

	static func fromBaseUnit(value: NumberType) -> GenericForce {
		return GenericForce.Newton(value)
	}
}

//: Finally, let's declare a type to do our calcualtions
typealias Force = GenericForce<Double, Double>

//: That is how declare values
let f0 = Force.Newton(1)
let f1 = Force.Kilopound(1)

//: And that is how they work
print(10.0*f0 + f1/444.8221615255)

//: ## What about class and struct?
/*:
Imho it doesn't make sense to construct something with reference semantics, but `struct` is a choice that is at least as well suited as `enum`:
You loose the conversion and the nice summary (`description` always includes the title of the unit), but those could be added.
*/

public struct Time: Quantity {
	typealias NumberType = NSTimeInterval

	public let value: NSTimeInterval

	func toBaseUnit() -> NumberType {
		return value
	}

	static func fromBaseUnit(value: NumberType) -> Time {
		return Time(value: value)
	}
}
