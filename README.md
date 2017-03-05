# Ashen

A framework for writing terminal applications in Swift.
Based on [Elm](http://elm-lang.org) (very similar paradigm to
[React](https://facebook.github.io/react/)).

## main.swift, running your program

To run an application, an app and run it, passing in a program and a screen.  It
will return `.quit` or `.error`, depending on how the program exited.  The
default provided `Screen` is recommended for the screen parameter, but in theory
you could create a `ScreenType` that runs on iOS or outputs HTML.

```swift
let app = App(program: YourProgram(), screen: Screen())
let state = app.run()

switch state {
    case .quit: exit(EX_OK)
    case .error: exit(EX_IOERR)
}
```

## Writing a `Program`

Here's a skeleton program template:

```swift
struct SpinnersDemo: Program {
    // this is usually an enum, but it can be any type.  Your app will respond
    // to state changes by accepting a `Message` and returning a modified
    // `Model`.
    enum Message {
        case quit  // You can compose/stack programs, but your top-level program
    }              // will need a way to exit.

    // The entired state of you program will be stored here, so a struct is the
    // most common type.
    struct Model {
    }

    // Commands will be discussed in the context of `update`, but tl;dr they are
    // ways to interface with external event sources, e.g. HTTP requests.
    // Usually an enum.
    enum Command {
    }

    // return your initial model - if your app requires an asynchronous
    // "loading" spinner, you could use a `loading/loaded/error` enum to
    // represent those states
    func model() -> Model {
        return Model()
    }

    // Ashen will call this method with the current model, and a message that
    // you use to change the model.  This will result in a screen refresh, but
    // it also means that your Program is very easy to test; pass a model to
    // this method along with the message you want to test, and check the values
    // of the model.
    //
    // The return value also includes a list of "commands".  Commands are
    // another form of event emitters, like Components, but they talk with
    // external services, either asynchronously or synchronously.
    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        return (model, [], .quit)
    }

    // Finally the render() method is given a model and a size, and you return
    // a component - usually a Window or Box that contains child components. The
    // screenSize is used to assist view sizing or adaptive layouts.  render()
    // is also called when the window is resized().
    func render(model: Model, in screenSize: Size) -> Component {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            return SpinnerView(.mc(x: 2 * i - model.spinners.count / 2), model: spinnerModel)
        }
        return Window(
            components: spinners + [
                OnKeyPress(.key_enter, { return Message.quit }),
            ])
    }

    // The `start` function is called with your command, and a callback you can
    // call with one of your Program's `Message` values.  The `done` callback is
    // often called asynchronously, e.g. after an HTTP or background process.
    func start(command: Command, done: @escaping (Message) -> Void) {
    }
}
```
