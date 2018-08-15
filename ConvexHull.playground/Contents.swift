// Compass points refer to relative location of points (.up = maximum y coordinate) as well as direction of travel (e.g. up = north)
enum Direction: String {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
}

typealias Point = (x: Int, y: Int)
typealias Vector = (terminalPoint: Point, slope: Double, magnitute: Double)
typealias Directions = (Direction?, Direction?)

// Counterclockwise path around a set of 2D inflection points moves in this order
// Visualize that you're moving around a regular octogon starting from the left-bottom
let validPath: [String] = ["SE", "E", "NE", "N", "NW", "W", "SW", "S"]

// Description of a set of inflection points
// Ordered from leftmost bottom point (WS, or west-south-most) counterclockwise around a shape
let localMaximums = ["WS", "SW", "SE", "ES", "EN", "NE", "NW", "WN"]

// Main function.  Takes a set of arbitrary points (n >= 3) and returns an ordered subset of those points representing its convex hull
func convexHull(_ points: [Point]) -> [Point] {
    let exteriorPoints = removeInteriorPoints(points)
    let concavePath = hullPath(exteriorPoints)
    //print("concave path: \(concavePath)")
    let convexPath = removeConcavePoints(concavePath)
    //print("convex path:  \(convexPath)")
    let efficientConvexPath = removeColinearPoints(convexPath)
    return efficientConvexPath
}

// This is what makes a general (ordered) path into a convex one
// Traverses a path and ensures all turns are counterclockwise and occur at hull points
func removeConcavePoints(_ path: [Point]) -> [Point] {
    var lastValidPointIndex = 0
    var lastValidDirectionIndex = 0
    var testPointIndex = 1
    var trimmedPath: [Point] = [path[0]]
    let validPathDirections: [Directions] = validPath.map{ directions($0) }
    
    //TODO check connection between path[n-1] and path[0] to ensure last point fits
    while testPointIndex < path.count {
        let lastValidPoint = path[lastValidPointIndex]
        let lastValidDirections = validPathDirections[lastValidDirectionIndex]
        let testPoint = path[testPointIndex]
        let pathDirections = directionsBetween(p1: lastValidPoint, p2: testPoint)
        
        if pathDirections == lastValidDirections {
            trimmedPath.append(testPoint)
            lastValidPointIndex = testPointIndex
        } else {
            let testDirectionsIndex = validDirectionsIndex(pathDirections)
            let testInflectionPoint = inflectionPoint(path, directions: directions(localMaximums[testDirectionsIndex]))
            if testDirectionsIndex >= lastValidDirectionIndex && testInflectionPoint == lastValidPoint {
                trimmedPath.append(testPoint)
                lastValidPointIndex = testPointIndex
                lastValidDirectionIndex = testDirectionsIndex
            }
        }
        testPointIndex += 1
    }
    return trimmedPath
}

// Removes points that are between a grid of inflection points, meaning they cannot be on the hull
func removeInteriorPoints(_ points: [Point]) -> [Point] {
    //TODO implement to pre-optimize concave path function call
    return points
}

// Generates a directed path from an arbitrary set of points
func hullPath(_ points: [Point]) -> [Point] {
    let leftMostPoint: Point = inflectionPoint(points, directions: (.west, .south))
    var vectorSet = vectors(leftMostPoint, terminalPoints: points)
    vectorSet.sort { (lhs, rhs) in
        return lhs.slope < rhs.slope || (lhs.slope == rhs.slope && lhs.magnitute < rhs.magnitute)
    }
    var path = vectorSet.map { return $0.terminalPoint }
    path.insert(leftMostPoint, at: 0)
    return path
}

// Generates some vectors from a stationary point.
// Facilitates the ordering of points used to make up the initial path
func vectors(_ initialPoint: Point, terminalPoints: [Point]) -> [Vector] {
    var vectors: [Vector] = []
    terminalPoints.forEach { terminalPoint in
        if terminalPoint.x == initialPoint.x && terminalPoint.y == initialPoint.y {
            return
        }
        let relativeSlope = slope(p1: initialPoint, p2: terminalPoint)
        let relativeMagnitude = magnitudeSquared(p1: initialPoint, p2: terminalPoint)
        let vector: Vector = (terminalPoint, relativeSlope, relativeMagnitude)
        vectors.append(vector)
    }
    return vectors
}

// Gets rid points that will not affect hull shape (including duplicates)
func removeColinearPoints(_ points: [Point]) -> [Point] {
    //TODO implement to remove redundant hull points
    return points
}

// Convenience func to turn strings to Direction-Tuples, e.g. NW -> (.north, .west)
func directions(_ s: String) -> Directions {
    let first = charAt(s, i: 0)
    let second = charAt(s, i: 1)
    return (Direction(rawValue: first)!, Direction(rawValue: second))
}

// Find a char in a UTF8 string.  Unicode will break
func charAt(_ s: String, i: Int) -> String {
    guard i < s.count else {
        return ""
    }
    return String(s[s.index(s.startIndex, offsetBy: i)])
}

// Convenience func to turn Direction-Tuples into strings, e.g. (.north, .west) -> NW
func desc(_ d: Directions?) -> String {
    return (d?.0?.rawValue ?? "") + (d?.1?.rawValue ?? "")
}

// Return the direction between two points.  For example (0, 0) to (1, 1) will return (.north, .east)
func directionsBetween(p1: Point, p2: Point) -> Directions {
    var dirs: [Direction] = []
    if p1.y < p2.y {
        dirs.append(.north)
    } else if p1.y > p2.y {
        dirs.append(.south)
    }
    if p1.x < p2.x {
        dirs.append(.east)
    } else if p1.x > p2.x {
        dirs.append(.west)
    }
    let d1: Direction? = dirs.count > 0 ? dirs[0] : nil
    let d2: Direction? = dirs.count > 1 ? dirs[1] : nil
    return (d1, d2)
}

// Searches for and returns local extreme point.
// For instance (.north, .east) will return the north-most point (if multiple, the east-most of those is used to break the tie)
func inflectionPoint(_ points: [Point], directions: Directions) -> Point {
    return maximums(maximums(points, direction: directions.0!), direction: directions.1!).first!
}

// Helper function for "infectionPoint" call.  This finds all points at the maximum direction
// For instance .north returns the northmost point and all other points that are equally north
func maximums(_ points: [Point], direction: Direction) -> [Point] {
    var bestPoint: Point = points.first!
    var bestPoints: [Point] = [bestPoint]
    points.forEach { comparePoint in
        var bestValue = 0
        var compareValue = 0
        switch direction {
            case .east, .west:
                bestValue = bestPoint.x
                compareValue = comparePoint.x
            case .north, .south:
                bestValue = bestPoint.y
                compareValue = comparePoint.y
        }
        if bestValue == compareValue {
            bestPoints.append(comparePoint)
        } else if (maximum(lhs: bestValue, rhs: compareValue, direction: direction) == compareValue) {
            bestPoint = comparePoint
            bestPoints = [bestPoint]
        }
    }
    return bestPoints
}

// Helper for above function.  Selects the "most" of a direction.  .north returns the max y value.  .south returns the min.
func maximum(lhs: Int, rhs: Int, direction: Direction) -> Int {
    switch direction {
    case .south, .west:
        return lhs < rhs ? lhs : rhs
    case .north, .east:
        return lhs > rhs ? lhs : rhs
    }
}

func validDirectionsIndex(_ directions: Directions) -> Int {
    return validPath.index(of: desc(directions)) ?? -1
}

// Helper function for computing vectors
func slope(p1: Point, p2: Point) -> Double {
    let xdiff = Double(p2.x - p1.x)
    let ydiff = Double(p2.y - p1.y)
    if xdiff == 0 {
        return Double.greatestFiniteMagnitude
    }
    return ydiff / xdiff
}

// Helper function for computing vectors.  No need for square root since it's only a comparison value
func magnitudeSquared(p1: Point, p2: Point) -> Double {
    let xdiff = Double(p2.x - p1.x)
    let ydiff = Double(p2.y - p1.y)
    return xdiff * xdiff + ydiff * ydiff
}

let triangle: [Point] = [(1, 1), (3, 3), (2, 2)]
print("triangle: \(convexHull(triangle))")
// triangle: [(x: 1, y: 1), (x: 2, y: 2), (x: 3, y: 3)]

let square: [Point] = [(0, 0), (1, 0), (1, 1), (0, 1)]
print("square  : \(convexHull(square))")
// square  : [(x: 0, y: 0), (x: 1, y: 0), (x: 1, y: 1), (x: 0, y: 1)]

let octogon: [Point] = [(0, 1), (1, 0), (2, 0), (3, 1), (3, 2), (2, 3), (1, 3), (0, 2)]
print("octogon : \(convexHull(octogon))")
// octogon : [(x: 0, y: 1), (x: 1, y: 0), (x: 2, y: 0), (x: 3, y: 1), (x: 3, y: 2), (x: 2, y: 3), (x: 1, y: 3), (x: 0, y: 2)]

// the convex hull of a cross shape should be an octogon
let cross: [Point] = [(0, 1), (1, 1), (1, 0), (2, 0), (2, 1), (3, 1), (3, 2), (2, 2), (2, 3), (1, 3), (1, 2), (0, 2)]
print("cross   : \(convexHull(cross))")
// cross   : [(x: 0, y: 1), (x: 1, y: 0), (x: 2, y: 0), (x: 3, y: 1), (x: 3, y: 2), (x: 2, y: 3), (x: 1, y: 3), (x: 0, y: 2)]

let testPoints: [Point] = [(0, 3), (2, 2), (1, 1), (2, 1), (3, 0), (0, 0), (3, 3)]
print("random  : \(convexHull(testPoints))")
// random  : [(x: 0, y: 0), (x: 3, y: 0), (x: 3, y: 3), (x: 0, y: 3)]
