.pragma library

function merge(text, fallback, key, widget, top) {
    var base
    try {
        base = JSON.parse(text)
    } catch (error) {
        base = fallback
    }
    var widgets = Object.assign({}, base.widgets)
    if (key)
        widgets[key] = Object.assign({}, widgets[key], widget)
    return JSON.stringify(Object.assign({}, base, top, {widgets: widgets}), null, 2) + "\n"
}
