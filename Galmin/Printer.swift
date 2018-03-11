//
//  Printer.swift
//  Galmin
//
//  Created by Ilya Kos on 2/22/18.
//  Copyright © 2018 Ilya Kos. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
    
    // Use fopen/fwrite to output string
    func writeStringToFile(string: String, path: String) -> Bool {
        let fp = fopen(path, "w"); defer { fclose(fp) }
        let byteArray = Array(string.utf8)
        let count = fwrite(byteArray, 1, byteArray.count, fp)
        return count == string.utf8.count
    }
    
    // Use fread to input string
    func readStringFromFile(path: String) -> String {
        let fp = fopen(path, "r"); defer { fclose(fp) }
        var outputString = ""
        let chunkSize = 1024
        let buffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer.allocate(capacity: chunkSize)
        defer { buffer.deallocate(capacity: chunkSize) }
        repeat {
            let count: Int = fread(buffer, 1, chunkSize, fp)
            guard ferror(fp) == 0 else { break }
            if count > 0 {
                let ptr = unsafeBitCast(buffer, to: UnsafePointer<CChar>.self)
                if let newString = String(validatingUTF8: ptr) {
                    outputString += newString
                }
            }
        } while feof(fp) == 0
        
        return outputString
    }
    
    extension String {
        func write(with name: String) throws {
            if !writeStringToFile(string: self, path: "diskraDz3/\(name)") {
                print("Couldn't write files ¯\\_(ツ)_/¯")
            }
        }
    }
#else
    private extension String {
        func write(with name: String) throws {
            try self.write(toFile: "diskraDz3/\(name)", atomically: true, encoding: .utf8)
        }
    }
#endif

private extension String {
    var sub: String {
        return self.map { c in
            switch c {
            case "0":
                return "₀"
            case "1":
                return "₁"
            case "2":
                return "₂"
            case "3":
                return "₃"
            case "4":
                return "₄"
            case "5":
                return "₅"
            case "6":
                return "₆"
            case "7":
                return "₇"
            case "8":
                return "₈"
            case "9":
                return "₉"
            case "(":
                return "₍"
            case ")":
                return "₎"
            default:
                return String(c)
            }
        }.joined()
    }
    var sup: String {
        return self.map { c in
            switch c {
            case "0":
                return "⁰"
            case "1":
                return "¹"
            case "2":
                return "²"
            case "3":
                return "³"
            case "4":
                return "⁴"
            case "5":
                return "⁵"
            case "6":
                return "⁶"
            case "7":
                return "⁷"
            case "8":
                return "⁸"
            case "9":
                return "⁹"
            case "(":
                return "⁽"
            case ")":
                return "⁾"
            default:
                return String(c)
            }
        }.joined()
    }
}

class Printer<Vertex> where Vertex: Hashable & Comparable {
    
    private func table(`for` matrix: [Vertex: [Vertex: Weight]], with reductions: (starts: [Vertex: Int], ends: [Vertex: Int]), prefix: String, coef: Bool) -> String {
        var out: [[String]] = []
        let ends = matrix.values.first!.keys.sorted()
        let sEnds = ends.map({"\($0)"})
        let row: [String] = ["S" + prefix.sub] + sEnds + (reductions.starts.count > 0 ? ["min"] : [])
        out.append(row)
        for start in matrix.keys.sorted() {
            var nextRow = ["\(start)"] + ends.map {"\(matrix[start]![$0]!)" + (coef && matrix[start]![$0]! == .value(0) ? "\(coeficient(for: matrix, start: start, end: $0))".sup : "")}
            if let reduction = reductions.starts[start] {
                nextRow.append("\(reduction)")
            }
            out.append(nextRow)
        }
        if reductions.ends.count > 0 {
            out.append(["min"] + ends.map {reductions.ends[$0] == nil ? "" : "\(reductions.ends[$0]!)"})
        }
        return out.reduce("") {$0 + $1.reduce("", {"\($0)\($1), "}).dropLast(2) + "\n"}
    }
    
    func processMinimizations(_ minimizations: (initial: [Vertex: [Vertex: Weight]], includingTables: Graph<Vertex>.Minimization, excludingTables: Graph<Vertex>.Minimization), prefix: String, counter: Int) -> () {
        do {
            try table(for: minimizations.initial, with: ([:], [:]), prefix: prefix, coef: true).write(with: "\(counter)_1.csv")
            try table(for: minimizations.includingTables.before, with: minimizations.includingTables.reductions, prefix: prefix + "1", coef: false).write(with: "\(counter)_2.csv")
            try table(for: minimizations.includingTables.after, with: ([:], [:]), prefix: prefix + "1", coef: false).write(with: "\(counter)_3.csv")
            try table(for: minimizations.excludingTables.before, with: minimizations.excludingTables.reductions, prefix: prefix + "0", coef: false).write(with: "\(counter)_4.csv")
            try table(for: minimizations.excludingTables.after, with: ([:], [:]), prefix: prefix + "0", coef: false).write(with: "\(counter)_5.csv")
        } catch {
            print("Couldn't write files ¯\\_(ツ)_/¯")
        }
    }

    private var solutions: FileHandle!
    
    func processInitialMinimization(minimization: Graph<Vertex>.Minimization, counter: Int) -> () {
        do {
            try FileManager.default.createDirectory(atPath: "diskraDz3", withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: "diskraDz3/solutions.txt", contents: nil)
            solutions = FileHandle(forWritingAtPath: "diskraDz3/solutions.txt")
            try table(for: minimization.before, with: minimization.reductions, prefix: "", coef: false).write(with: "\(counter)_1.csv")
            try table(for: minimization.after, with: ([:], [:]), prefix: "", coef: false).write(with: "\(counter)_2.csv")
        } catch {
            print("Couldn't write files ¯\\_(ツ)_/¯")
        }
    }
    
    func processTree(tree: Tree<Vertex>, selecting: Tree<Vertex>?, counter: Int) -> () {
        var nodeCounter = 0
        func process(tree: Tree<Vertex>) -> (declarations: [String], graph: [String], node: Int) {
            let node = nodeCounter
            nodeCounter += 1
            var declarations: [String] = []
            var graph: [String] = []
            var edge = ""
            if let selected = tree.chosenEdge {
                edge = "<sub><i>(\(selected.start), \(selected.end))</i></sub>"
            }
            var solution = ""
            if let s = tree.solution {
                solution = "<sub><i><u>\(s.map({String(describing: $0)}).joined())</u></i></sub>"
            }
            declarations.append("\(node) [label=<S\(tree.prefix.sub)<sup><b>\(tree.minWeight)</b></sup>\(edge)\(solution)>\( tree === selecting ? " shape=ellipse" : " shape=box" )]")
//            declarations.append("\(node) [label=<S\(tree.prefix.sub)<sup>\(tree.minWeight)</sup>\(edge)>\( tree === selecting ? " color=\"red\"" : "" )]")
////            declarations.append("\(node) [label=<S<sub>\(tree.prefix.count == 0 ? " " : tree.prefix)</sub><sup>\(tree.minWeight)</sup>\(edge)>\( tree === selecting ? " color=\"red\"" : "" )]")
//////            declarations.append("\(node) [label=\"S\(tree.prefix.count == 0 ? "" : tree.prefix.sub)\(String(tree.minWeight).sup)\(edge.sub)\"\( tree === selecting ? " color=\"red\"" : "" )]")
            if let (including, excluding) = tree.nodes {
                let excludingResult = process(tree: excluding)
                declarations.append(contentsOf: excludingResult.declarations)
                graph.append("\(node) -> \(excludingResult.node)")
                graph.append(contentsOf: excludingResult.graph)
                let includingResult = process(tree: including)
                declarations.append(contentsOf: includingResult.declarations)
                graph.append("\(node) -> \(includingResult.node)")
                graph.append(contentsOf: includingResult.graph)
            }
            return (declarations, graph, node)
        }
        let (declaration, graph, _) = process(tree: tree)
        let out = """
            digraph {
                {
                    \(declaration.joined(separator: "\n\t"))
                }
                \(graph.joined(separator: "\n"))
            }
            """
        do {
            try out.write(with: "\(counter).gv")
        } catch {
            print("Couldn't write files ¯\\_(ツ)_/¯")
        }
    }
    
    func processResult(tree: Tree<Vertex>, counter: Int) -> () {
        solutions.seekToEndOfFile()
        let text = "Step: \(counter) \tweight = \(tree.minWeight) \tsolution: (\(tree.solution!.map({String(describing: $0)}).joined(separator: ", ")))\n"
//        print(text)
        solutions.write(text.data(using: .utf8)!)
    }
    
    func flushResults() {
        solutions.truncateFile(atOffset: 0)
    }
    
}

extension Tree {
    var path: [Vertex] {
        let graph = self.value
        var edges = graph.usedEdges + graph.finalSolution()
        var vertices: Set<Vertex> = []
        for (start, end) in edges {
            vertices.insert(start)
            vertices.insert(end)
        }
        var out: [Vertex] = [vertices.min()!]
        edgesLoop: while edges.count > 0 {
            for (i, edge) in edges.enumerated() {
                if edge.start == out.last! {
                    out.append(edge.end)
                    edges.remove(at: i)
                    continue edgesLoop
                }
            }
            fatalError()
        }
        return Array(out.dropLast())
    }
}


