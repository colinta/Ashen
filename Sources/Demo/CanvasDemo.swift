////
///  CanvasDemo.swift
//

import Darwin
import Foundation

struct CanvasDemo: Program {
    enum Message {
        case tick
        case toggleAnimation
        case offset(Float)
        case offsetReset
        case quit
    }

    struct Model {
        var animating: Bool
        var date: Date
        var timeOffset: TimeInterval
    }

    func initial() -> (Model, [AnyCommand]) {
        return (Model(animating: false, date: Date(), timeOffset: 0), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [AnyCommand], LoopState) {
        switch message {
        case .tick:
            model.date = Date()
        case .toggleAnimation:
            model.animating = !model.animating
        case let .offset(dt):
            model.timeOffset += TimeInterval(dt)
        case .offsetReset:
            model.timeOffset = 0
        case .quit:
            return (model, [], .quit)
        }
        return (model, [], .continue)
    }

    private func lpad(_ time: Int, as component: NSCalendar.Unit) -> String {
        if component == .hour && time == 0 {
            return "12"
        }
        else if component == .hour && time > 12 {
            return lpad(time - 12, as: .hour)
        }
        else if time < 10 {
            return "0\(time)"
        }
        return "\(time)"
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let date = model.date.addingTimeInterval(model.timeOffset)
        let hour = Float(NSCalendar.current.component(.hour, from: date))
        let minute = Float(NSCalendar.current.component(.minute, from: date))
        let second = Float(NSCalendar.current.component(.second, from: date))
        let totalSeconds = (hour * 3600 + minute * 60 + second)

        let hourRadius: Float = 0.6
        let hourAngle = hour * 2 * Float(M_PI) / 12
        let hourPt = FloatPoint(
            x: hourRadius * cos(Float(M_PI) / 2 - hourAngle),
            y: hourRadius * sin(Float(M_PI) / 2 - hourAngle)
            )
        let minuteRadius: Float = 0.8
        let minuteAngle = minute * 2 * Float(M_PI) / 60
        let minutePt = FloatPoint(
            x: minuteRadius * cos(Float(M_PI) / 2 - minuteAngle),
            y: minuteRadius * sin(Float(M_PI) / 2 - minuteAngle)
            )
        let secondRadius: Float = 1
        let secondAngle = second * 2 * Float(M_PI) / 60
        let secondPt = FloatPoint(
            x: secondRadius * cos(Float(M_PI) / 2 - secondAngle),
            y: secondRadius * sin(Float(M_PI) / 2 - secondAngle)
            )

        let canvasSize = min((screenSize.width - 2) / 2, screenSize.height - 13)
        let timingComponent: Component
        if model.animating {
            timingComponent = OnNext({ return Message.offset(3601) })
        }
        else {
            timingComponent = OnTick({ _ in return Message.tick }, every: 0.1)
        }

        let watchFrame = FloatFrame(x: -1, y: -1, width: 2, height: 2)
        let watchDecorations: [CanvasView.Drawable] = [
            .line(FloatPoint(x: watchFrame.minX, y: 0), FloatPoint(x: watchFrame.minX + 0.1, y: 0)),
            .line(FloatPoint(x: watchFrame.maxX, y: 0), FloatPoint(x: watchFrame.maxX - 0.1, y: 0)),
            .line(FloatPoint(x: 0, y: watchFrame.minY), FloatPoint(x: 0, y: watchFrame.minY + 0.1)),
            .line(FloatPoint(x: 0, y: watchFrame.maxY), FloatPoint(x: 0, y: watchFrame.maxY - 0.1)),
        ]

        let timeChars = ["🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘",]
        let timeChr = timeChars[Int(totalSeconds * Float(timeChars.count) / 86400)]
        return Window(components: [
            OnKeyPress(.key_up, { return Message.offset(3600) }),
            OnKeyPress(.key_down, { return Message.offset(-3600) }),
            OnKeyPress(.key_backspace, { return Message.offsetReset }),
            OnKeyPress(.key_enter, { return Message.quit }),
            OnKeyPress(.key_space, { return Message.toggleAnimation }),
            timingComponent,
            LabelView(.topLeft(x: 2), text: "\(lpad(Int(hour), as: .hour)):\(lpad(Int(minute), as: .minute)):\(lpad(Int(second), as: .second))\(hour >= 12 && hour < 24 ? "pm" : "am")"),
            CanvasView(.bottomLeft(), DesiredSize(width: screenSize.width, height: 10),
                viewport: FloatFrame(x: -43_200, y: -1, width: 86_400, height: 2),
                drawables: [
                    .line(FloatPoint(x: 0, y: -1), FloatPoint(x: 0, y: 1)),
                    .fn({ x in
                        return 0.5 - cos((totalSeconds + x) / 86_400 * 2 * Float(M_PI)) / 2
                    }),
                ]),
            CanvasView(.middleCenter(y: -4), DesiredSize(width: 2 * canvasSize, height: canvasSize),
                viewport: watchFrame,
                drawables: watchDecorations + [
                    .border,
                    .line(FloatPoint.zero, minutePt),
                    .line(FloatPoint.zero, hourPt),
                    .line(FloatPoint.zero, secondPt),
                ]),
            LabelView(.middleCenter(x: canvasSize / 2, y: canvasSize / 4 - 4), text: timeChr),
        ])
    }

    func start(command: AnyCommand, done: @escaping (Message) -> Void) {
    }

}
