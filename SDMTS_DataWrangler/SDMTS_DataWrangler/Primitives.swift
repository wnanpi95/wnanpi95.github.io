//
//  Primitives.swift
//  SDMTS_DataWrangler
//
//  Created by Will An on 8/9/17.
//  Copyright © 2017 Will An. All rights reserved.
//

import Foundation

struct Shape {
    let latitude: Float
    let longitude: Float
    let dist_traveled: Float
}

struct ShapeSeq {
    let latitude: Float
    let longitude: Float
    let dist_traveled: Float
    let sequence: Int
}

struct Position {
    let latitude: Float
    let longitude: Float
}

func -(lhs: Position, rhs: Shape) -> Position {
    return Position(latitude: lhs.latitude - rhs.latitude,
                    longitude: lhs.longitude - rhs.longitude)
}

func -(lhs: Position, rhs: Position) -> Position {
    return Position(latitude: lhs.latitude - rhs.latitude,
                    longitude: lhs.longitude - rhs.longitude)
}

func -(lhs: Shape, rhs: Shape) -> Shape {
    return Shape(latitude: lhs.latitude - rhs.latitude,
                 longitude: lhs.longitude - rhs.latitude,
                 dist_traveled: lhs.dist_traveled - rhs.dist_traveled)
}

func *(lhs: Shape, rhs: Shape) -> Float {
    return lhs.latitude*rhs.latitude + lhs.longitude*rhs.longitude
}

func *(lhs: Shape, rhs: Position) -> Float {
    return lhs.latitude*rhs.latitude + lhs.longitude*rhs.longitude
}

func *(lhs: Position, rhs: Position) -> Float {
    return lhs.latitude*rhs.latitude + lhs.longitude*rhs.longitude
}

func /(lhs: Position, rhs: Float) -> Position {
    return Position(latitude: lhs.latitude/rhs,
                    longitude: lhs.longitude/rhs)
}

func magnitude(shape: Shape) -> Float {
    return sqrt(shape.latitude*shape.latitude
        + shape.longitude*shape.longitude)
}

func magnitude(position: Position) -> Float {
    return sqrt(position.latitude*position.latitude
        + position.longitude*position.longitude)
}

struct RouteDirection: Hashable {
    let route: String
    let direction: String
    
    var hashValue: Int {
        return route.hashValue
    }
    
    static func == (lhs: RouteDirection, rhs: RouteDirection) -> Bool {
        return lhs.route == rhs.route && lhs.direction == rhs.direction
    }
}
