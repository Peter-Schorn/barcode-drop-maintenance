// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyLambda",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "BarcodeDropMaintenance", 
            targets: ["BarcodeDropMaintenance"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", 
            from: "1.0.0-alpha"
        ),
        .package(
            url: "https://github.com/swift-server/swift-aws-lambda-events.git", 
            branch: "main"
        ),
        .package(
            url: "https://github.com/orlandos-nl/MongoKitten.git", 
            from: "7.2.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "BarcodeDropMaintenance", 
            dependencies: [
                .product(
                    name: "AWSLambdaRuntime", 
                    package: "swift-aws-lambda-runtime"
                ),
                .product(
                    name: "AWSLambdaEvents", 
                    package: "swift-aws-lambda-events"
                ),
                .product(
                    name: "MongoKitten",
                    package: "MongoKitten"
                ),
                // .product(
                //     name: "Meow",
                //     package: "MongoKitten"
                // )
            ]
        ),
    ]
)
