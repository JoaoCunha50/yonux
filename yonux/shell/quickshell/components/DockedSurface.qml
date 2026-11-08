pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.theme

Item {
    id: root

    property int corner: Theme.radius.xl
    property color color: Theme.colors.bg
    readonly property Item panel: panel

    ConcaveCorner {}

    // For the future bordered window (ContentWindow) implementation, where there will be a concave corner at the bottom of the window as well.
    /*     ConcaveCorner {
        anchors.bottom: parent.bottom
        atBottom: false
    } */

    Rectangle {
        id: panel
        x: root.corner
        width: parent.width - root.corner
        height: parent.height
        color: root.color
    }

    component ConcaveCorner: Shape {
        id: concave

        property bool atBottom: false

        width: root.corner
        height: root.corner
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.color
            startX: root.corner
            startY: concave.atBottom ? 0 : root.corner

            PathLine {
                x: root.corner
                y: concave.atBottom ? root.corner : 0
            }
            PathLine {
                x: 0
                y: concave.atBottom ? root.corner : 0
            }
            PathArc {
                x: root.corner
                y: concave.atBottom ? 0 : root.corner
                radiusX: root.corner
                radiusY: root.corner
                direction: concave.atBottom ? PathArc.Counterclockwise : PathArc.Clockwise
            }
        }
    }
}
