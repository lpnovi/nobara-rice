import QtQuick

Rectangle {
    id: root
    color: "#050408"

    property int stage

    Image {
        anchors.centerIn: parent
        width: 220
        height: 220
        fillMode: Image.PreserveAspectFit
        source: "images/logo.png"
    }
}
