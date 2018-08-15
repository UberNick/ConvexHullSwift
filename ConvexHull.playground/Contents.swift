enum Direction: String {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
}

typealias Point = (x: Int, y: Int)
typealias Vector = (terminalPoint: Point, slope: Double, magnitute: Double)

typealias Directions = (Direction?, Direction?)

let validPath: [String] = ["SE", "E", "NE", "N", "NW", "W", "SW", "S"]
let localMaximums = ["WS", "SW", "SE", "ES", "EN", "NE", "NW", "WN"]

func desc(_ d: Directions?) -> String {
    return (d?.0?.rawValue ?? "") + (d?.1?.rawValue ?? "")
}

func directions(_ s: String) -> Directions {
    let first = charAt(s, i: 0)
    let second = charAt(s, i: 1)
    return (Direction(rawValue: first)!, Direction(rawValue: second))
}

func charAt(_ s: String, i: Int) -> String {
    guard i < s.count else {
        return ""
    }
    return String(s[s.index(s.startIndex, offsetBy: i)])
}

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

func removeConcavePoints(_ path: [Point]) -> [Point] {
    var lastValidPointIndex = 0
    var lastValidDirectionIndex = 0
    var testPointIndex = 1
    var trimmedPath: [Point] = [path[0]]
    
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

func inflectionPoint(_ points: [Point], directions: Directions) -> Point {
    return maximums(maximums(points, direction: directions.0!), direction: directions.1!).first!
}

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

let validPathDirections: [Directions] = validPath.map{ directions($0) }

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

func slope(p1: Point, p2: Point) -> Double {
    let xdiff = Double(p2.x - p1.x)
    let ydiff = Double(p2.y - p1.y)
    if xdiff == 0 {
        return Double.greatestFiniteMagnitude
    }
    return ydiff / xdiff
}

func magnitudeSquared(p1: Point, p2: Point) -> Double {
    let xdiff = Double(p2.x - p1.x)
    let ydiff = Double(p2.y - p1.y)
    return xdiff * xdiff + ydiff * ydiff
}

func hullPath(_ points: [Point]) -> [Point] {
    let leftMostPoint: Point = inflectionPoint(points, directions: (.west, .south))
    var vectorSet = vectors(leftMostPoint, terminalPoints: points)
    vectorSet.sort { (lhs, rhs) in
        return lhs.slope < rhs.slope || (lhs.slope == rhs.slope && lhs.magnitute < lhs.magnitute)
    }
    var path = vectorSet.map { return $0.terminalPoint }
    path.insert(leftMostPoint, at: 0)
    return path
}

func convexHull(_ points: [Point]) -> [Point] {
    let exteriorPoints = removeInteriorPoints(points)
    let concavePath = hullPath(exteriorPoints)
    
    print("concave path: \(concavePath)")
    
    let convexPath = removeConcavePoints(concavePath)
    
    print("convex path:  \(convexPath)")
    
    let efficientConvexPath = removeColinearPoints(convexPath)
    return efficientConvexPath
}

func removeInteriorPoints(_ points: [Point]) -> [Point] {
    //TODO implement for optimization
    return points
}

func removeColinearPoints(_ points: [Point]) -> [Point] {
    //TODO implement to remove redundant hull points
    return points
}

/*let triangle: [Point] = [(1, 1), (3, 3), (2, 2)]
print(trimmed(triangle))

let square: [Point] = [(0, 0), (1, 0), (1, 1), (0, 1)]
print(trimmed(square))

let octogon: [Point] = [(0, 1), (1, 0), (2, 0), (3, 1), (3, 2), (2, 3), (1, 3), (0, 2)]
print(trimmed(octogon))

let cross: [Point] = [(0, 1), (1, 1), (1, 0), (2, 0), (2, 1), (3, 1), (3, 2), (2, 2), (2, 3), (1, 3), (1, 2), (0, 2)]
print(trimmed(cross))*/

let points: [Point] = [(0, 3), (2, 2), (1, 1), (2, 1), (3, 0), (0, 0), (3, 3)]
convexHull(points)
