# Ashen

A framework for writing terminal applications in Swift. Based on [The Elm Architecture][Elm].

As a tutorial of Ashen, let's consider an application that fetches some todo
items and renders them as a list.

### Example

###### Old way

In a traditional controller/view pattern, views are created during
initialization, and updated later as needed with your application data.  Loading
data from a server to load a list of views might look something like this:

```swift
init() {
    label = LabelView(text: "Our Things:")
    label.isHidden = true

    loadingView = SpinnerView()
    loadingView.isHidden = false

    listView = ListView<Thing>()
    listView.rowHeight = 3
    listView.cellGenerator = cellForRow
    listView.isHidden = true

    startLoadingData(completion: loaded)
}

func loaded(data: [Thing]) {
    listView.data = data

    label.isHidden = false
    listView.isHidden = false
    loadingView.isHidden = true
}

func cellForRow(row: Thing) -> Component {
    LabelView(text: row.title)
}
```

###### New way

What would this look like using Ashen or Elm or React? In these frameworks,
rendering output is stateless; it is based the model, and you render *all* the
views and their properties based on that state.

```swift
func render(model: Model, in screenSize: Size) -> Component {
    guard
        let data = model.data
    else {
        // no data?  Show the spinner.  Defaults to centering itself in the
        // parent view.
        return SpinnerView()
    }

    // data is available - use a rowHeight based on the available viewport
    let rowHeight: Int
    if screenSize.height >= 30 {
      rowHeight = 3
    }
    else if screenSize.height >= 20 {
      rowHeight = 2
    }
    else {
      rowHeight = 1
    }

    return Window(components: [
        LabelView(text: "Our things"),
        ListView(dataList: data, rowHeight: rowHeight) { row in
            LabelView(text: row.title)
        }
        // 👆 this view is similar to how UITableView renders cells - only
        // the rows that are visible will be rendered. rowHeight can also be
        // assigned a function, btw, to support dynamic heights.
        //
        // Also, this view is not done yet! Sorry - but it'll look something
        // like this.
    ])
}
```

So instead of mutating the `isHidden` property of these views, we render the views
we need based on our model.

###### Async tasks

To fetch our data, we need to call out to the runtime to ask it to perform a
background task, aka a `Command`, and then report the results back as a
`Message`. `Message` is how your Components can tell your application about
changes that *might* result in a change to your model.  For instance, if someone
types in a "name" text field you probably want to know about that so you can
update the model's `name` property.

Sources of Messages include Views, Commands, and system event components
(e.g. a `KeyEvent` message is created via the `OnKeyPress` component, which
receives system-level events and maps those into an instance of your app's
`Message` type).

Our application starts at the `initial()` method.  We return our initial model
and a list of commands to run.  We will add an `Http` Command:

```swift
enum Message {
    case received(Result<(Int, Headers, Data), HttpError>)
}

func initial() -> (Model, [Command]) {
    let url = URL(string: "http://example.com")!
    let cmd = Http.get(url) { result in
      Message.received(result)
    }

    return (Model(), [cmd])
}
```

When the Http request succeeds (or fails) the result will be turned into an
instance of your application's `Message` type (usually an enum), and passed to
the `update()` function that you provide.

###### Updating

In your application's `update()` function, you will instruct the runtime how the
message affects your state.  Your options are:

- `.noChange` — ignore the message
- `.model()`  — return an updated model (shortcut for `.update(model, [])`)
- `.update()` — return a model and a list of Commands to run
- `.quit`     — graceful exit (usually means exit with status 0)
- `.quitAnd()`— graceful exit with a closure that runs just before the runtime
  is done cleaning up
- `.error()`  — indicate that an error occurred (usually means exit with non-zero status)

# Program

Here's a skeleton program template:

```swift
// `Program` defines the methods that you need to define in order to be loaded
// by `App`.  If you are designing a subprogram, you need not adhere to
// `Program`, though it is handy because you can easily test *just* that part of
// your application.
struct SpinnersDemo: Program {
    // This is usually an enum, but it can be any type.  Your app will respond
    // to state changes by accepting a `Message` and returning a modified
    // `Model`.
    enum Message {
        case quit  // You can compose/stack programs, but your top-level program
    }              // will need a way to exit.

    // The entired state of you program will be stored here, so a struct is the
    // most common type.
    struct Model {
    }

    // Return your initial model and commands. if your app requires
    // initialization from an API (i.eg. a loading spinner), use a
    // `loading/loaded/error` enum to represent the initial state.  If you
    // persist your application to the database you could load that here, either
    // synchronously or via a `Command`.
    func initial() -> (Model, [Command]) {
        (Model(), [])
    }

    // Ashen will call this method with the current model, and a message that
    // you use to update your model.  This will result in a screen refresh, but
    // it also means that your program is very easy to test; pass a model to
    // this method along with the message you want to test, and check the values
    // of the model.
    //
    // The return value also includes a list of "commands".  Commands are
    // another form of event emitters, like Components, but they talk with
    // external services, either asynchronously or synchronously.
    func update(model: inout Model, message: Message)
        -> Update<Model>
    {
        .noChange
        // or .stop(.quit)
        // or .stop(.error)
        // or .model(model)
        // or .commands([])
        // or .update(model, [])
    }

    // Finally the render() method is given a model and a size, and you return
    // a component - usually a Window or Box that contains child components. The
    // screenSize is used to assist view sizing or adaptive layouts.  render()
    // is also called when the window is resized.
    func render(model: Model, in screenSize: Size) -> Component {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            SpinnerView(.middleCenter(x: 2 * i - model.spinners.count / 2), model: spinnerModel)
        }
        return Window(
            components: spinners + [
                OnKeyPress(.enter, { Message.quit }),
            ])
    }

    // The `start` function is called with your command, and a callback you can
    // call with one of your program's `Message` values.  The `send` callback is
    // called asynchronously, e.g. after an HTTP or background process.  It can
    // be called any number of times, e.g. for progress messages.
    func start(command: Command, send: @escaping (Message) -> Void) {
    }
}
```

## Running your Program

To run your program, create an app and run it, passing in a program and a
screen.  It will return `.quit` or `.error`, depending on how the program
exited.  `TermboxScreen` is recommended for the screen parameter, but in theory
you could create a `ScreenType` for other output paradigms.

```swift
let app = App(program: YourProgram())  // default screen is TermboxScreen()
let state = app.run()

switch state {
    case .quit: exit(EX_OK)
    case .error: exit(EX_IOERR)
}
```

Important note: ALL Ashen programs can be aborted using `ctrl+c` and `ctrl+d`.
`ctrl+c` is considered an error/abort and `ctrl+d` is considered a graceful
exit.  If you want to respond to these events, you can include special messages
to `Ashen.run()`:

```swift
let app = App(program: YourProgram())  // default screen is TermboxScreen()
```

## Location and Size structs

The `Location` struct is used to place your views relative to their parent
container.  There are nine locations:

```
+------------+--------------+-------------+
|topLeft     |   topCenter  |     topRight|  `topLeft` is so common, it has a
|aka `at`    |   aka `top`  |             |  shorthand.
|            |              |             |
+------------+--------------+-------------+  The default value for most views
|            |              |             |  is at (x: 0, y: 0)
|middleLeft  | middleCenter |  middleRight|
|            | aka `center` |             |
+------------+--------------+-------------+
|            |              |             |
|            | aka `bottom` |             |
|bottomLeft  | bottomCenter |  bottomRight|
+------------+--------------+-------------+
```

`Size` and `DesiredSize` work hand in hand - most `ComponentView` classes expect
an instance of `DesiredSize`, but some prefer an explicit `Size`, or others
don't accept any size parameter.  Regardless, *all* views implement
`func desiredSize() -> DesiredSize`, which tells parent views the ideal size for
this view.  This class has a lot of flexibility; it supports literal numbers
(`DesiredSize(width: 100, height: 1)`), "largest of" values, and even accepts a
closure that returns a size dynamically, based on the size of the parent view.

Another way to have dynamic sizing, and this was shown above, is to change the
layout based on the `screenSize: Size` that is passed to `render()`.

###### Examples:

```swift
LabelView(at: .at(5, 10))  // label at x: 5, y: 10
LabelView(at: .middleCenter())
LabelView(at: .bottomRight(y: -1))  // in bottomRight corner, and up 1 row
```

Sizes can be defined absolutely, or relative to the parent view, and with positive
or negative offsets.

```swift
// assume the parent container is width: 80, height: 30

LabelView(size: DesiredSize(width: 5, height: 10))
LabelView(size: DesiredSize(width: 10, height: .percent(100)))
// -> width: 10, height: 30
LabelView(size: DesiredSize(width: .max.minus(4), height: .percent(50).plus(5)))
// -> width: 76, height: 20
```

Using these location and size descriptions, you can accomplish the majority of
your UI, but you can also choose to use `Layout` classes like `FlowLayout` to
position views in a stack or row, and `GridLayout` to specify rows and columns
of views, with weights to describe the relative sizes.

## Views

Todo: list the available views

[Elm]: http://elm-lang.org
[React]: https://facebook.github.io/react/
