//
//  Graph.swift
//  Galmin
//
//  Created by Ilya Kos on 2/17/18.
//  Copyright © 2018 Ilya Kos. All rights reserved.
//

import Foundation


/// Full graph
struct Graph<Vertex> where Vertex: Hashable & Comparable {
    private var weights: [Vertex: [Vertex: Weight]] = [:]
    private var usedVertices: Set<Vertex>
    var usedEdges: [(start: Vertex, end: Vertex)] = []
    /// Not actual min weight. It's the minimal possible weight.
    var minWeight = 0
    
    var graphWeights: [Vertex: [Vertex: Weight]] {
        return weights
    }
    
    var components: [Set<Vertex>] {
        var out: [Set<Vertex>] = []
        for edge in usedEdges {
            var first: Set<Vertex>!
            for (i, component) in out.enumerated() {
                if component.contains(edge.start) {
                    first = out.remove(at: i)
                    break // Since only one component can contain a vertex
                }
            }
            if first == nil {
                first = Set([edge.start])
            }
            var second: Set<Vertex>!
            for (i, component) in out.enumerated() {
                if component.contains(edge.end) {
                    second = out.remove(at: i)
                    break // Since only one component can contain a vertex
                }
            }
            if second == nil {
                second = Set([edge.end])
            }
            out.append(first.union(second))
        }
        return out
    }
    
    private mutating func deleteEdge(from start: Vertex, to end: Vertex) {
        weights[start] = nil
        weights = weights.mapValues { row in
            var row = row
            row[end] = nil
            return row
        }
        weights[end]?[start]? = .infinity
    }

    typealias Minimization = (before: [Vertex: [Vertex: Weight]], after: [Vertex: [Vertex: Weight]], reductions: (starts: [Vertex: Int], ends: [Vertex: Int]))

    mutating func minimize() -> Minimization {
        assert(!weights.isEmpty)
        // Minimize rows
        let before = weights
        var starts: [Vertex: Int] = [:]
        for (key, row) in weights {
            let offset = row.values.min()!
            if offset.numValue == 0 {
                continue
            }
            starts[key] = offset.numValue
            minWeight += offset.numValue
            weights[key] = row.mapValues {$0 - offset}
        }
        
        // Minimize columns
        var ends: [Vertex: Int] = [:]
        for key in weights.first!.value.keys {
            let offset = weights.values.map({$0[key]!}).min()!
            if offset.numValue == 0 { // Just optimization
                continue
            }
            ends[key] = offset.numValue
            minWeight += offset.numValue
            weights = weights.mapValues { row in
                var row = row
                row[key]! -= offset
                return row
            }
        }
        let after = weights
        return (before: before, after: after, reductions: (starts: starts, ends: ends))
    }
    
    mutating func step() -> (start: Vertex, end: Vertex)? {
        if weights.isEmpty {
            return nil
        }

//        let reductions = minimize() // Should minimize on creation
        
        var start: Vertex!
        var end: Vertex!
        var maxCoef = -1
        
        for row in weights {
            for weight in row.value {
                if weight.value == .value(0) {
                    let coef = coeficient(for: weights, start: row.key, end: weight.key)
                    if coef > maxCoef {
                        start = row.key
                        end = weight.key
                        maxCoef = coef
                    }
                }
            }
        }
        
        usedVertices.insert(start)
        usedVertices.insert(end)
        
        deleteEdge(from: start, to: end)
        
        usedEdges.append((start, end))
        
        for component in components {
            for start in component {
                for end in component {
                    weights[start]?[end]? = .infinity
                }
            }
        }
        
        return (start, end)
    }
    
    func validate() -> Bool {
        var ends: [Vertex: Bool] = weights.mapValues {_ in false} // Valid?
        for row in weights.values {
            if !row.values.reduce(false, {$1 != .infinity ? true : $0}) {
                return false
            }
            ends.filter({!$0.value}).keys.forEach { key in
                if row[key] != .infinity {
                    ends[key] = true
                }
            }
        }
        if ends.values.contains(false) {
            return false
        }
        return true
    }
    
    func finalSolution() -> [(start: Vertex, end: Vertex)] {
        assert(weights.count == 2)
        var found: (start: Vertex, end: Vertex)?
        for (start, row) in weights {
            for (end, weight) in row {
                if weight == .value(0) {
                    if let found = found {
                        return [found, (start, end)]
                    } else {
                        found = (start, end)
                    }
                }
            }
        }
        fatalError("finalSolution fell through. Most likeley: didn't minimize.")
    }
    
    var power: Int {
        return weights.count + (weights.first?.value.count ?? 0) -
            weights.values.reduce(0) {$0 + $1.values.filter({$0 == .infinity}).count}
    }
    
    mutating func exclude(edge: (start: Vertex, end: Vertex)) {
        weights[edge.start]![edge.end] = .infinity
    }
    
    init(with weights: [Vertex: [Vertex: Weight]], used usedVertices: Set<Vertex>) {
        self.weights = weights
        self.usedVertices = usedVertices
    }
}

enum Weight: Comparable, CustomStringConvertible {
    static func <(lhs: Weight, rhs: Weight) -> Bool {
        switch lhs {
        case .infinity:
            return false
        case .value(let lv):
            switch rhs {
            case .infinity:
                return true
            case .value(let rv):
                return lv < rv
            }
        }
    }
    
    static func ==(lhs: Weight, rhs: Weight) -> Bool {
        switch lhs {
        case .infinity:
            if case .infinity = rhs {
                return true
            } else {
                return false
            }
        case .value(let lv):
            if case let .value(rv) = rhs {
                return lv == rv
            } else {
                return false
            }
        }
    }
    
    case infinity
    case value(Int)
    
    var numValue: Int {
        switch self {
        case .infinity:
            return 0
        case .value(let v):
            return v
        }
    }
    
    static func -(lhs: Weight, rhs: Weight) -> Weight {
        return lhs - rhs.numValue
    }
    static func -(lhs: Weight, rhs: Int) -> Weight {
        if case let .value(v) = lhs {
            return .value(v - rhs)
        } else {
            return .infinity
        }
    }
    static func -=(lhs: inout Weight, rhs: Weight) {
        lhs = lhs - rhs
    }
    
    var description: String {
        switch self {
        case .value(let v):
            return "\(v)"
        case .infinity:
            return "∞"
        }
    }
}

func coeficient<Vertex>(`for` weights: [Vertex: [Vertex: Weight]], start: Vertex, end: Vertex) -> Int {
    return weights[start]!.filter({$0.key != end}).values.min()!.numValue +
        weights.filter({$0.key != start}).reduce(Weight.infinity) {min($0, $1.value[end]!)}.numValue

}

