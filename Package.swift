import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Epoch.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/Zewo/WebSocket.git", majorVersion: 0, minor: 1)
    ]
)
