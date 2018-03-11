//
//  main.swift
//  Galmin
//
//  Created by Ilya Kos on 2/17/18.
//  Copyright © 2018 Ilya Kos. All rights reserved.
//

import Foundation

let printer = Printer<Int>()

print("Enter your values in the folowing format:")
print("(x0, y0): 1 2")

var inputs: [Int: (x: Int, y: Int)] = [:]

func iter(i: Int) {
    if let next = readLine(strippingNewline: true)?.split(separator: " ", omittingEmptySubsequences: true).flatMap({Int($0)}),
        next.count == 2,
        let x = next.first,
        let y = next.last {
        inputs[i] = (x, y)
    } else {
        print("nope.")
        iter(i: i)
    }
}

for i in 1...6 {
    print("(x\(i), y\(i)): ", terminator: "")
    iter(i: i)
}

//inputs = [1: (4, 1), 2: (4, 3), 3: (2, 7), 4: (9, 6), 5: (10, 7), 6: (6, 10)]

var weights: [Int: [Int: Int]] = [:]

for (start, sVal) in inputs {
    weights[start] = [:]
    for (end, eVal) in inputs {
        weights[start]![end] = abs(sVal.x - eVal.x) + abs(sVal.y - eVal.y)
    }
}

let solver = Solver<Int>(weights: weights)

solver.processInitialMinimization = printer.processInitialMinimization
solver.processMinimizations = printer.processMinimizations
solver.processResult = printer.processResult
solver.processTree = printer.processTree
solver.flushResults = printer.flushResults

solver.start()

print("""

+-------+
| i l y |
| a k o |
| o o 0 |
+-------+
""")
