# Ashen

A framework for writing terminal applications in Swift. Based on [The Elm Architecture][elm].

As a tutorial of Ashen, let's consider an application that fetches some todo
items and renders them as a list.

### Example

###### Old way

In a traditional controller/view pattern, views are created during
initialization, and updated later as needed with your application data. Loading
data from a server to load a list of views. Views are stored in instance
variables and edited "in place", and the views/subviews are added/removed as
events happen, so a lot of code is there to manage view state.

###### New way

What would this look like using Ashen or Elm or React? In these frameworks,
rendering output is declarative; it is based the model, and you render _all_ the
views and their properties based on that state. Model goes in, View comes out.

```swift
func render(model: Model) -> View<Message> {
    guard
        let data = model.data
    else {
        // no data?  Show the spinner.
        return Spinner()
    }

    return Stack(.topToBottom, [
        Text("List of things"),
        ListView(dataList: data) { row in
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

So instead of mutating the `isHidden` property of views, or `addSubview`, we
just render the views we need based on our model.  SwiftUI has also adopted this
model, so if you've been using it, Ashen will feel very familiar.

###### Commands and Messages

To fetch our data, we need to call out to the runtime to ask it to perform a
background task, aka a `Command`, and then report the results back as a
`Message`. `Message` is how your Components can tell your application about
changes that _might_ result in a change to your model. For instance, if someone
types in a "name" text field you probably want to know about that so you can
update the model's `name` property.

Sources of Messages include Views, Commands, and system event components
(e.g. a `KeyEvent` message can be captured via the `OnKeyPress` component, which
receives system-level events and maps those into an instance of your app's
`Message` type).

Our application starts at the `initial()` method. We return our initial model
and a command to run. We will return an `Http` command:

```swift
enum Message {
    case received(Result<(Int, Headers, Data), HttpError>)
}

func initial() -> Initial<Model, Message> {
    let url = URL(string: "http://example.com")!
    let cmd = Http.get(url) { result in
      Message.received(result)
    }

    return Initial(Model(), cmd)
}
```

When the Http request succeeds (or fails) the result will be turned into an
instance of your application's `Message` type (usually an enum), and passed to
the `update()` function that you provide.

To send multiple commands, group them with `Command.list([cmd1, cmd2, ...])`

###### Updating

In your application's `update()` function, you will instruct the runtime how the
message affects your state. Your options are:

-   `.noChange` — ignore the message
-   `.update(model, command)` — return a model and a list of Commands to run
-   `.quit` — graceful exit (usually means exit with status 0)
-   `.quitAnd({ ... })`— graceful exit with a closure that runs just before the runtime
    is done cleaning up. You can also throw an error in that closure.

For convenience there are two helper "types":

-   `.model(model)` — return just updated model, no commands (shortcut for `.update(model, Command.none())`)
-   `.error(error)` — quit and raise an error.

# Program

Here's a skeleton program template:

```swift
// This is usually an enum, but it can be any type.  Your app will respond
// to state changes by accepting a `Message` and returning a modified
// `Model`.
enum Message {
    case quit
}

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
func update(model: Model, message: Message)
    -> State<Model, Message>
{
    switch message {
    case .quit:
        return .quit
    }
}

// Finally the render() method is given your model and you return
// an array of views. Why an array? I optimized for the common case: some key
// handlers, maybe some mouse events, and a "main" view.
func render(model: Model) -> [View<Message>] {
    [
        OnKeyPress(.enter, { Message.quit }),
        Frame(Spinner(), .alignment(.middleCenter)),
    ])
}
```

## Running your Program

To run your program, pass your `initial`, `update`, `view`, and `unmount`
functions to `Ashen.Program` and run it with `ashen(program)`. It will return
`.quit` or `.error`, depending on how the program exited.

```swift
do {
    try ashen(Program(initial, update, view))
    exit(EX_OK)
} catch {
    exit(EX_IOERR)
}
```

*Important note*: ALL Ashen programs can be aborted using `ctrl+c`. It is
_recommended_ that you support `ctrl+\` to gracefully exit your program.

# Views

- `Text()` - display text or attributed text.
    ```swift
    Text("Some plain text")
    Text("Some underlined text".underlined())
    ```
- `Input()` - editable text, make sure to pass `.isResponder(true)` to the active `Input`.
    ```swift
    enum Message {
        case textChanged(String)
    }
    Input("Editable text", Message.textChanged, .isResponder(true))
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
        (.flex1, Text(Hi!).underlined()), // this view will stretch to fill the available space
        // .flex1 is a handy alias for .flex(1) - just like CSS flex: 1, you can use different flex
        // values to give more or less % of the available space to the subviews
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
- `Scroll(view, .offset(pt|x:|y:))` - Make a view scrollable. By default the scroll view does not respond to key or mouse events. To make the view scrollable via mouse, try this:
    ```swift
    enum Message {
        case scroll(Int)  // update model.scrollY by this value
    }
    OnMouseWheel(
        Scroll(Stack(.down, [...]), .offset(model.scrollY)),
        Message.scroll
    )
    ```
    Also consider adding a "listener" for the `onResizeContent:` message, which will pass a `LocalViewport` (which has the `size` of the entire scrollable area and the `visible: Rect`)
- `Repeating(view)` - Useful for background drawing. By itself it has `preferredSize: .zero`, but will draw the passed `view` to fill the available area.
    ```swift
    // draw the text "Hi!" centered, then fill the rest of the background with red.
    ZStack([Frame(Text("Hi!".background(.red)), .alignment(.middleCenter)), Repeating(Text(" ".background(.red)))])
    ```

## View Modifiers

Views can be created in a fluent syntax (these will feel much like SwiftUI, though not nearly that level of complexity & sophistication).

- `.size(preferredSize), .minSize(preferredSize), .maxSize(preferredSize)` - ensures the view is at least, exactly, or at most `preferredSize`. See also `.width(w), .minWidth(w), .maxWidth(w), .height(h), .minHeight(h), .maxHeight(h)` to control only the width or height.
    ```swift
    Text("Hi!").width(5)
    Stack(.ltr, [...]).maxSize(Size(width: 20, height: 5))
    ```
- `.matchContainer(), .matchContainer(dimension: .width|.height)` - Ignores the view's preferred size in favor of the size provided by the containing view.
- `.matchSize(ofView: view), .matchSize(ofView: view, dimension: .width|.height)` - Ignores the view's preferred size in favor of another view (usually a sibling view, in a ZStack).
- `.fitInContainer(.width|.height)` - Make sure the width or height is equal to or less than the containing view's width or height.
- `.compact()` - Usually the containing view's size is passed to the view's `render` function, even if it's much more than the preferred size. This method renders the view using the `preferredSize` instead.
- `.padding(left:,top:,right:,bottom:)` or `.padding(Insets)` - Increases the preferred size to accommodate padding, and renders the view inside the padded area. If you are interested in peaking into some simple rendering/masking code, this is a good place to start.
- `.styled(Attr)` - After drawing the view, the rendered area is modified to include the `Attr`. See also: `underlined()`, `bottomLined()`, `reversed()`, `bold()`, `foreground(color:)`, `background(color:)`, `reset()`
    ```swift
    Text("Hi!".underlined()).background(color: .red)
    Stack(.ltr, [...]).reversed()
    ```
- `.border(BoxBorder)` - Surrounds the view in a border.
    ```swift
    Text("Hi!").border(.single, .title("Message"))
    ```
- `.aligned(Alignment)` - This is useful when you know a view will be rendered in an area much larger than the view's `preferredSize`. The `Alignment` options are `topLeft`, `topCenter`, `topRight`, `middleLeft`, `middleCenter`, `middleRight`, `bottomLeft`, `bottomCenter`, `bottomRight`.
    ```swift
    Text("Hi!").aligned(.middleCenter)
    ```
    See also `.centered()`, which is shorthand for `.aligned(.topCenter)`, useful for centering text or a group of views.
- `.scrollable(offset: Point)` - Wraps the view in `Scroll(view, .offset(offset))`

# Events

- `OnKeyPress`
- `OnTick`
- `OnResize`
- `OnNext`
- `OnClick`
- `OnMouseWheel`
- `OnMouse`
- `IgnoreMouse`

[elm]: http://elm-lang.org
[react]: https://facebook.github.io/react/
