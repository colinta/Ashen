# Ashen

A framework for writing terminal applications in Swift. Based on [The Elm Architecture][elm].

As a tutorial of Ashen, let's consider an application that fetches some todo
items and renders them as a list.

### Example

###### Old way

In a traditional controller/view pattern, views are created during
initialization, and updated later as needed with your application data. Loading
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
rendering output is stateless; it is based the model, and you render _all_ the
views and their properties based on that state.

```swift
func render(model: Model, size: Size) -> View<Message> {
    guard
        let data = model.data
    else {
        // no data?  Show the spinner.  Defaults to centering itself in the
        // parent view.
        return Spinner()
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

    return Stack(.topToBottom, [
        Text("Our things"),
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
changes that _might_ result in a change to your model. For instance, if someone
types in a "name" text field you probably want to know about that so you can
update the model's `name` property.

Sources of Messages include Views, Commands, and system event components
(e.g. a `KeyEvent` message is created via the `OnKeyPress` component, which
receives system-level events and maps those into an instance of your app's
`Message` type).

Our application starts at the `initial()` method. We return our initial model
and a list of commands to run. We will add an `Http` Command:

```swift
enum Message {
    case received(Result<(Int, Headers, Data), HttpError>)
}

func initial() -> Initial<Model, Message> {
    let url = URL(string: "http://example.com")!
    let cmd = Http.get(url) { result in
      Message.received(result)
    }

    return Initial(Model(), [cmd])
}
```

When the Http request succeeds (or fails) the result will be turned into an
instance of your application's `Message` type (usually an enum), and passed to
the `update()` function that you provide.

###### Updating

In your application's `update()` function, you will instruct the runtime how the
message affects your state. Your options are:

-   `.noChange` — ignore the message
-   `.update(model, [cmds])` — return a model and a list of Commands to run
-   `.quit` — graceful exit (usually means exit with status 0)
-   `.quitAnd({ ... })`— graceful exit with a closure that runs just before the runtime
    is done cleaning up. You can also throw an error in that closure.

For convenience there are two helper "types":

-   `.model(model)` — return just updated model, no commands (shortcut for `.update(model, [])`)
-   `.error(error)` — quit and raise an error.

# Program

Here's a skeleton program template:

```swift
// `Program` defines the methods that you need to define in order to be loaded
// by `App`.  If you are designing a subprogram, you need not adhere to
// `Program`, though it is handy because you can easily test *just* that part of
// your application.
struct SpinnersDemo {
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
    func initial() -> Initial<Model, Message> {
        Initial(Model())
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
        -> State<Model, Message>
    {
        switch message {
        case .quit:
            return .quit
        }
    }

    // Finally the render() method is given a model and a size, and you return
    // a component - usually a Window or Box that contains child components. The
    // screenSize is used to assist view sizing or adaptive layouts.  render()
    // is also called when the window is resized.
    func render(model: Model, in screenSize: Size) -> View<Message> {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            Spinner(.middleCenter(x: 2 * i - model.spinners.count / 2), model: spinnerModel)
        }
        return Stack(.down, // alias for .topToBottom
            spinners + [
                OnKeyPress(.enter, { Message.quit }),
            ])
    }
}
```

## Running your Program

To run your program, pass your `initial`, `update`, and `view`, passing in a program and a
screen. It will return `.quit` or `.error`, depending on how the program
exited. `TermboxScreen` is recommended for the screen parameter, but in theory
you could create a `ScreenType` for other output paradigms.

```swift
do {
    try Ashen(Program(initial, update, view))
    exit(EX_OK)
} catch {
    exit(EX_IOERR)
}
```

Important note: ALL Ashen programs can be aborted using `ctrl+c` and `ctrl+\`.
`ctrl+c` is considered an error/abort and `ctrl+\` is considered a graceful
exit.

# Views

- `Text()` - display text or attributed text.
    ```swift
    Text("Some plain text")
    Text("Some underlined text".underlined())
    ```
- `Box()` - surround a view with a customizable border.
    ```swift
    Box(view)
    Box(view, .border(.double))
    Box(view, .border(.double), .title("Welcome".bold()))
    ```
- `Flow()` - arrange views using a flexbox *like* layout.
    ```swift
    Flow(.leftToRight, [  // alias: .ltr
        (.fixed, Text(" ")),
        (.flex(1), Text(Hi!).underlined()), // this view will stretch to fill the available space
        (.fixed, Text(" ")),
    ])
    Flow(.bottomToTop, views)
    ```
- `Columns()` - arrange views horizontally, equally sized and taking up all space.
    ```swift
    Columns(views)
    ```
- `Rows()` - arrange views vertically, equally sized and taking up all space.
    ```swift
    Rows(views)
    ```
- `Stack()` - arrange views according to their preferred (usually smallest) size.
    ```swift
    Stack(.ltr, views)
    ```
- `Frame()` - place a view inside a container that fills the available space, and supports alignment.
    ```swift
    Frame(Text("Hi!"), .alignment(.middleCenter))
    ```
- `Spinner()` - show a simple 1x1 spinner animation
    ```swift
    Spinner()
    ```

## View Modifiers

Views can be created in a fluent syntax (these will feel much like SwiftUI, though not nearly that level of complexity & sophistication).



[elm]: http://elm-lang.org
[react]: https://facebook.github.io/react/
