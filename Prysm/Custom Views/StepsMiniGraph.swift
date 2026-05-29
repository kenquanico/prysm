//
//  StepsMiniGraph.swift
//  Prysm
//
//  Created by Ken Aldrey Quanico on 5/26/26.
//


import SwiftUI
import CoreGraphics

struct StepsMiniGraph: View {
var body: some View {
Path { path in
path.move(to: CGPoint(x: 0, y: 25))
path.addLine(to: CGPoint(x: 15, y: 18))
path.addLine(to: CGPoint(x: 30, y: 22))
path.addLine(to: CGPoint(x: 45, y: 10))
path.addLine(to: CGPoint(x: 60, y: 14))
path.addLine(to: CGPoint(x: 70, y: 8))
}
.stroke(Color.blue.opacity(0.8), lineWidth: 2)
}
}

struct FocusMiniGraph: View {
var body: some View {
Path { path in
path.move(to: CGPoint(x: 0, y: 20))
path.addLine(to: CGPoint(x: 15, y: 22))
path.addLine(to: CGPoint(x: 30, y: 12))
path.addLine(to: CGPoint(x: 45, y: 18))
path.addLine(to: CGPoint(x: 60, y: 10))
path.addLine(to: CGPoint(x: 70, y: 16))
}
.stroke(Color.purple.opacity(0.8), lineWidth: 2)
}
}

struct ScheduleMiniGraph: View {
var body: some View {
Path { path in
path.move(to: CGPoint(x: 0, y: 18))
path.addLine(to: CGPoint(x: 15, y: 18))
path.addLine(to: CGPoint(x: 30, y: 12))
path.addLine(to: CGPoint(x: 45, y: 20))
path.addLine(to: CGPoint(x: 60, y: 14))
path.addLine(to: CGPoint(x: 70, y: 16))
}
.stroke(Color.teal.opacity(0.8), lineWidth: 2)
}
}