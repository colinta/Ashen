////
///  Rouge.swift
//

import Darwin


struct Rouge: Program {
    enum Message {
        case quit
        case revive
        case tick(Float)
        case resize(Size)
        case moveLeft
        case moveRight
        case moveUp
        case moveDown
    }

    struct Train {
        enum Direction {
            case right
            case left
            case down
            case up
        }
        enum Graphics: UInt32 {
            case one = 0
            case two = 1
            case three = 2
            case four = 3
        }

        var origin: FloatPoint
        var direction: Direction
        var graphics: Graphics
        var speed: Float
        var cars: Int

        var minX: Int {
            switch direction {
            case .left:  return Int(origin.x + 0.5)
            case .right: return maxX - 3 * cars
            case .up:    return Int(origin.x + 0.5)
            case .down:  return Int(origin.x + 0.5)
            }
        }
        var minY: Int {
            switch direction {
            case .left:  return Int(origin.y + 0.5)
            case .right: return Int(origin.y + 0.5)
            case .up:    return Int(origin.y + 0.5)
            case .down:  return maxY + 3 * cars
            }
        }
        var maxX: Int {
            switch direction {
            case .left:  return minX + 3 * cars
            case .right: return Int(origin.x + 0.5)
            case .up:    return Int(origin.x + 0.5)
            case .down:  return Int(origin.x + 0.5)
            }
        }
        var maxY: Int {
            switch direction {
            case .left:  return minY + 1
            case .right: return Int(origin.y + 0.5)
            case .up:    return minY + 3 * cars
            case .down:  return Int(origin.y + 0.5)
            }
        }

        func moveTrain(dt: Float, in screenSize: Size) -> Train? {
            let size = FloatSize(screenSize)
            var nextTrain = self
            let delta = dt * speed
            switch direction {
            case .right:
                nextTrain.origin = FloatPoint(x: nextTrain.origin.x + delta, y: nextTrain.origin.y)
                guard nextTrain.origin.x < size.width + Float(cars) else { return nil }
            case .left:
                nextTrain.origin = FloatPoint(x: nextTrain.origin.x - delta, y: nextTrain.origin.y)
                guard nextTrain.origin.x > -Float(1 + cars * 3) else { return nil }
            case .down:
                nextTrain.origin = FloatPoint(x: nextTrain.origin.x, y: nextTrain.origin.y + delta)
                guard nextTrain.origin.y < size.height + Float(cars) else { return nil }
            case .up:
                nextTrain.origin = FloatPoint(x: nextTrain.origin.x, y: nextTrain.origin.y - delta)
                guard nextTrain.origin.y > -Float(cars) else { return nil }
            }

            return nextTrain
        }

        func createComponent() -> Component {
            let train: String
            let cars: String
            switch graphics {
            case .one:
                train = "🚂"
                cars = String(repeating: "  🚃", count: self.cars)
            case .two:
                train = "🚐"
                cars = String(repeating: "  🚗", count: self.cars)
            case .three:
                train = "🛥"
                cars = String(repeating: "  🚤", count: self.cars)
            case .four:
                train = "🚁"
                cars = String(repeating: "  🚲", count: self.cars)
            }
            return LabelView(.tl(x: minX, y: minY), text: train + cars)
        }
    }

    struct Model {
        var location: Point?
        var size: Size?
        var trains: [Train]
        var dead: Bool
        var addTrainTimeout: Float
    }

    func model() -> Model {
        return Model(location: nil, size: nil, trains: [], dead: false, addTrainTimeout: 1)
    }

    private func randFloat(min: Float, max: Float) -> Float {
        return CFloat(Double(min) + drand48() * Double(max - min))
    }

    private func createTrain(in size: Size) -> Train {
        let graphics = Train.Graphics(rawValue: arc4random_uniform(4)) ?? Train.Graphics.one
        let direction: Train.Direction, x: Float, y: Float
        switch arc4random_uniform(2) {
        case 0:
            direction = .right
            // x = -1
            // y = 1 + Float(arc4random_uniform(UInt32(max(0, size.height - 2))))
        case 1:
            direction = .left
            // x = Float(size.width) + 1
            // y = 1 + Float(arc4random_uniform(UInt32(max(0, size.height - 2))))
        case 2:
            direction = .down
            // x = 1 + Float(arc4random_uniform(UInt32(size.width - 2)))
            // y = -1
        default:
            direction = .up
            // x = 1 + Float(arc4random_uniform(UInt32(size.height - 2)))
            // y = Float(size.height) + 1
        }
        x = Float(size.width) + 1
        y = 1 + Float(arc4random_uniform(UInt32(max(0, size.height - 2))))

        return Train(
            origin: FloatPoint(x: x, y: y),
            direction: .left, // direction,
            graphics: graphics,
            speed: randFloat(min: 10, max: 25),
            cars: Int(4 + arc4random_uniform(10))
            )
    }

    func update(model: inout Model, message: Message)
        -> (Model, [AnyCommand], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case .revive:
            var nextModel = self.model()
            nextModel.size = model.size
            return (nextModel, [], .continue)
        case let .tick(dt):
            guard
                !model.dead,
                let modelLocation = model.location,
                let size = model.size
            else { break }

            if model.addTrainTimeout - dt <= 0 {
                model.trains.append(createTrain(in: size))
                model.addTrainTimeout = randFloat(min: 4, max: 8)
            }
            else {
                model.addTrainTimeout -= dt
            }

            let nextTrains = model.trains.flatMap {
                $0.moveTrain(dt: dt, in: size)
            }

            if nextTrains.index(where: { train in
                return
                    modelLocation.y >= train.minY &&
                    modelLocation.y < train.maxY &&
                    modelLocation.x >= train.minX &&
                    modelLocation.x < train.maxX
            }) != nil {
                model.dead = true
            }
            else {
                model.trains = nextTrains
            }
        case let .resize(size):
            model.size = size
            model.location = move(
                model: model,
                by: Point.zero) ?? Point(x: size.width / 2, y: size.height / 2)
        case .moveLeft:
            model.location = move(model: model, by: Point(x: -1, y: 0))
        case .moveRight:
            model.location = move(model: model, by: Point(x: 1, y: 0))
        case .moveUp:
            model.location = move(model: model, by: Point(x: 0, y: -1))
        case .moveDown:
            model.location = move(model: model, by: Point(x: 0, y: 1))
        }

        return (model, [], .continue)
    }

    private func move(model: Model, by offset: Point) -> Point? {
        guard !model.dead else { return nil }
        guard let location = model.location, let size = model.size else { return nil }

        let x = min(max(location.x + offset.x, 0), size.width - 1)
        let y = min(max(location.y + offset.y, 0), size.height - 1)
        return Point(x: x, y: y)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        guard let modelLocation = model.location else { return OnNext({ return Message.resize(screenSize) }) }

        let keyHandlers: [Component]
        if model.dead {
            keyHandlers = [
                OnKeyPress({ _ in return Message.revive }, reject: [.key_enter]),
            ]
        }
        else {
            keyHandlers = [
                OnKeyPress(.key_left, { return Message.moveLeft }),
                OnKeyPress(.key_right, { return Message.moveRight }),
                OnKeyPress(.key_up, { return Message.moveUp }),
                OnKeyPress(.key_down, { return Message.moveDown }),
            ]
        }
        let trains = model.trains.map {
            $0.createComponent()
        }
        return Window(components: keyHandlers + trains + [
            OnKeyPress(.key_enter, { return Message.quit }),
            LabelView(.topLeft(modelLocation), text: model.dead ? "☠" : "☻"),
            OnResize(Message.resize),
            OnTick(Message.tick),
            ])
    }

    func start(command: AnyCommand, done: @escaping (Message) -> Void) {
    }
}
