import QtQuick
import QtQuick.Effects

ShaderEffect {
    property real strength: 0.35
    property real grainSize: 1.5
    property vector2d resolution: Qt.vector2d(width, height)

    fragmentShader: Qt.resolvedUrl("noise.frag.qsb")
}
