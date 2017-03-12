# Ashen

A framework for writing terminal applications in Swift.
Based on [Elm][] (very similar paradigm to
[React][]).

In theory it's totally possible to create a `ScreenType` that could render
something other than terminal output, but that's not why I built it.  Since
programmers spend so much time in the terminal, it makes a lot of sense to write
quick applications that don't require opening a GUI.  Plus, terminal apps are
cool in an old-school kinda way.

As a tutorial of Ashen, let's consider an application that fetches some content
and renders them as a list.

### Browsing

In a traditional controller/view pattern, views are created during
initialization, and updated later as needed with your application data.  Loading
data from a server to load a list of views might look something like this:

```swift
init() {
    label = LabelView()
    label.text = "Our Things"
    label.hidden = true
    loadingView = SpinnerView()
    listView = ListView()
    loading = true

    loadingView.hidden = false
    loadingView.startAnimating()
    listView.hidden = true

    startLoadingData(completion: loaded)
}

func loaded(data: [Thing]) {
    label.hidden = false
    listView.data = data
    listView.hidden = false
    loadingView.hidden = true
}

func cellForRow(row: Thing) -> Component {
    return LabelView(text: row.title)
}
```

What would this look like using Ashen or Elm or React? In these frameworks,
rendering output is stateless; it is based the model, and you render *all* the
views and their properties based on that state.

```swift
func render(model: Model) -> Component {
    if let data = model.data {
        return Window(components: [
            LabelView(text: "Our things"),
            OptimizedListView(dataList: data, rowHeight: 3) { row in
                return LabelView(text: row.title)
            }
            // 👆 this view is similar to how UITableView renders cells - only
            // the rows that are visible will be rendered. rowHeight can also be
            // assigned a function, btw, to support dynamic heights.
        ])
    }
    else {
        return SpinnerView()
    }
}
```

So instead of mutating the `hidden` property of these views, we render the views
we need based on our model.

To fetch our data, we need to call out to the runtime to ask it to perform a
background task, and then report the results back as a `Message`. `Message` is
how your components (aka views, but also system event emitters) can tell your
application about changes that *might* result in a change to your model.  For
instance, if someone types in a "name" text field you probably want to know
about that so you can update the model's `name` property.

When they press the "save" button you will want to save that data to your web
server - this is where the `Command` type comes in.  In this case we can create
an `HTTP.put` command instance, and when it is complete (or times out) we will
receive another `Message` letting us know.

Our work starts at the `initial()` method.  We return our initial model and a
list of commands to run.

```swift
func initial() -> (Model, [Command]) {
    let url = URL(string: "http://example.com")!
    return (Model(), [Http.get(url, [.timeout(5)])])
}
```

## Location and Size structs

The `Location` struct is used to place your views relative to their parent
container.  There are nine locations:

```
+------------+--------------+-------------+
|topLeft     |   topCenter  |     topRight|  `topLeft` is so common, it has a
|aka `at`    |              |             |  shorthand.
|            |              |             |
+------------+--------------+-------------+  The default value for most views
|            |              |             |  is at (x: 0, y: 0)
|middleLeft  | middleCenter |  middleRight|
|            |              |             |
+------------+--------------+-------------+
|            |              |             |
|            |              |             |
|bottomLeft  | bottomCenter |  bottomRight|
+------------+--------------+-------------+
```

```swift
     Examples:
LabelView(.at(5, 10))  // label at x: 5, y: 10
LabelView(.middleCenter())
LabelView(.bottomRight(y: -1))  // in bottomRight corner, and up 1 row
```

Sizes can be defined absolutely, or relative to the parent view, and with positive
or negative offsets.  They are also chainable, for a more descriptive API.

```swift
// assume the parent container is width: 80, height: 30
LabelView(.size(5, 10))  // width: 5, height: 10
LabelView(.width(10).height(percent: 100))  // width: 10, height: 30
LabelView(.fullWidth(minus: 4).height(times: 0.5, plus: 5))  // width: 76, height: 20
```

###### Available size functions:
```
.size(width:, height:)
.minus(0)  .minus(width:, height:)
.plus(0)   .plus(width:, height:)
.width(width) /* default height is 1 */      .height(height)  /* default width is 1 */
.parentWidth(percent: 0...100, plus: 0, minus: 0)  .parentHeight(percent: 0...100, plus: 0, minus: 0)
.parentWidth(times: 0...1, plus: 0, minus: 0)      .parentHeight(times: 0...1, plus: 0, minus: 0)
.fullWidth(plus: 0, minus: 0)                .fullHeight(plus: 0, minus: 0)
```

Using these location and size descriptions, you can accomplish the majority of your UI, but you can
also choose to use `Layout` classes like `FlowLayout` to position views in a
stack or row, and `GridLayout` to specify rows and columns of views, with weights to describe the
relative sizes.

## Views



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

    // Commands will be discussed in the context of `update`, but tl;dr they are
    // ways to interface with external event sources, e.g. HTTP requests.
    // Usually an enum.
    enum Command {
    }

    // Return your initial model and commands. if your app requires
    // initialization from an API (i.eg. a loading spinner), use a
    // `loading/loaded/error` enum to represent the initial state.  If you
    // persist your application to the database you could load that here, either
    // synchronously or via a `Command`.
    func initial() -> (Model, [Command]) {
        return Model()
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
        -> (Model, [Command], AnyMessage?)
    {
        return (model, [], SystemMessage.quit)
    }

    // Finally the render() method is given a model and a size, and you return
    // a component - usually a Window or Box that contains child components. The
    // screenSize is used to assist view sizing or adaptive layouts.  render()
    // is also called when the window is resized().
    func render(model: Model, in screenSize: Size) -> Component {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            return SpinnerView(.middleCenter(x: 2 * i - model.spinners.count / 2), model: spinnerModel)
        }
        return Window(
            components: spinners + [
                OnKeyPress(.key_enter, { return Message.quit }),
            ])
    }

    // The `start` function is called with your command, and a callback you can
    // call with one of your program's `Message` values.  The `done` callback is
    // often called asynchronously, e.g. after an HTTP or background process.
    func start(command: Command, done: @escaping (Message) -> Void) {
    }
}
```

[Elm]: http://elm-lang.org
[React]: https://facebook.github.io/react/
