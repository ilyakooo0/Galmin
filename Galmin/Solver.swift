//
//  Tree.swift
//  Galmin
//
//  Created by Ilya Kos on 2/17/18.
//  Copyright © 2018 Ilya Kos. All rights reserved.
//

import Foundation

class Solver<Vertex> where Vertex: Hashable & Comparable {
    
    private var tree: Tree<Vertex>
    
    init(weights: [Vertex: [Vertex: Int]]) {
        var weights = weights.mapValues {$0.mapValues {Weight.value($0)}}
        for key in weights.keys {
            weights[key]![key] = .infinity
        }
        tree = Tree(with: Graph(with: weights, used: [])) // TODO: Need to minimize initial tree
        
    }
    
    var counter = 1
    
    var processInitialMinimization: ((Graph<Vertex>.Minimization, _ counter: Int) -> ())?
    var processMinimizations: (((initial: [Vertex: [Vertex: Weight]], includingTables: Graph<Vertex>.Minimization, excludingTables: Graph<Vertex>.Minimization), _ prefix: String ,_ counter: Int) -> ())?
    var processTree: ((Tree<Vertex>, _ selecting: Tree<Vertex>?, _ counter: Int) -> ())?
    var processResult: ((Tree<Vertex>, _ counter: Int) -> ())?
    var flushResults: (() -> ())?
    
    private var solutions: [Tree<Vertex>] = []
    
    
    func start() {
        solutions = []
        
        var root = tree.value
        
        let minimization = root.minimize()
        
        tree = Tree(with: root)
        
        processInitialMinimization?(minimization, counter)
//        processTree?(tree, tree, counter)
        var minResult: Int?

        largeLoop: while true {
            counter += 1
            
            let next = tree.leaves.lazy.filter({!self.solutions.contains($0)}).min()!
//            print(next.minWeight)
            processTree?(tree, next, counter)
            let (minimizations, result, excludeResults) = next.step()
            processMinimizations?(minimizations, next.prefix, counter)
            
            solutions.append(contentsOf: excludeResults)
            
            if let result = result {
//                print("\t\t\tFOUND: \(result.minWeight)")
                if minResult == nil {
                    minResult = result.minWeight
                } else {
                    if minResult! > result.minWeight {
                        flushResults?()
                        minResult = result.minWeight
                    }
                }
                if result.minWeight > minResult! {
                    solutions.append(result)
                    continue
                }
                processResult?(result, counter)
                solutions.append(result)
            }
            if let minResult = minResult {
                for leaf in tree.leaves.lazy.filter({!self.solutions.contains($0)}) {
//                    print("\t\(leaf.minWeight)")
                    if leaf.minWeight <= minResult {
                        continue largeLoop
                    }
                }
                processTree?(tree, nil, counter+1)
                break
            }
        }
    }
    
//    private func step() {
//        let next = tree.leaves.min()!
//        let minimizations = next.step()
//        processMinimizations?(minimizations)
//        processTree?(tree)
//    }
}


class Tree<Vertex>: Comparable where Vertex: Hashable & Comparable {
    let value: Graph<Vertex>
    var nodes: (including: Tree<Vertex>, excluding: Tree<Vertex>)?
    var chosenEdge: (start: Vertex, end: Vertex)?
    var prefix = ""
    var solution: [Vertex]?
    
    /// Steps the graph
    init(with graph: Graph<Vertex>) {
        self.value = graph
    }
    
    var leaves: [Tree<Vertex>] {
        if let (including, excluding) = nodes {
            return including.leaves + excluding.leaves
        } else {
            return [self]
        }
    }
    
    var minWeight: Int {
        return value.minWeight
    }
    
    var power: Int {
        return value.power
    }
    
    
    func step() -> ((initial: [Vertex: [Vertex: Weight]],
        includingTables: Graph<Vertex>.Minimization,
        excludingTables: Graph<Vertex>.Minimization),
        result: Tree<Vertex>?,
        excludeResults: [Tree<Vertex>]) {
            assert(nodes == nil)
            var including = value
            chosenEdge = including.step()
            var excluding = value
            excluding.exclude(edge: chosenEdge!)
            let includingTables = including.minimize()
            let excludingTables = excluding.minimize()
            
            
            let includingTree = Tree(with: including)
            includingTree.prefix = prefix + "1"
            let excludingTree = Tree(with: excluding)
            excludingTree.prefix = prefix + "0"
            
            var excludeResults: [Tree<Vertex>] = []
            
            if !including.validate() {
                excludeResults.append(includingTree)
            }
            if !excluding.validate() {
                excludeResults.append(excludingTree)
            }

            nodes = (including: includingTree, excluding: excludingTree)
            
            var includingResult: Tree<Vertex>?
            
            if including.graphWeights.count == 2 && including.validate() {
                includingResult = nodes?.including
                includingResult?.solution = includingResult!.path
            }

            return ((value.graphWeights, includingTables, excludingTables), includingResult, excludeResults)
    }
    
    // MARK: Comparable
    static func <(lhs: Tree<Vertex>, rhs: Tree<Vertex>) -> Bool {
        if lhs.minWeight < rhs.minWeight {
            return true
        } else if lhs.minWeight > rhs.minWeight {
            return false
        } else {
            if lhs.power < rhs.power {
                return true
            } else {
                return false
            }
        }
    }
    
    static func ==(lhs: Tree<Vertex>, rhs: Tree<Vertex>) -> Bool {
        return lhs.minWeight == rhs.minWeight && lhs.power == rhs.power
    }
}
