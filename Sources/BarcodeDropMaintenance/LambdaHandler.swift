import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import MongoKitten

// @main
struct LambdaHandler: SimpleLambdaHandler {
    
    /*
     Environment Variables:
        - BARCODE_DROP_DATABASE_PASSWORD:
            - The password for the MongoDB database.
     */

    // static let client: MongoDatabase = {
    //
    //     print("Initializing MongoDB client with lazy connection.")
    //
    //     guard let password = ProcessInfo.processInfo
    //             .environment["BARCODE_DROP_DATABASE_PASSWORD"] else {
    //         fatalError(
    //             """
    //             could not retrieve password from BARCODE_DROP_DATABASE_PASSWORD \
    //             environment variable
    //             """
    //         )
    //     }
    //
    //     print(
    //         """
    //         Retrieved BARCODE_DROP_DATABASE_PASSWORD from the environment \
    //         variables.
    //         """
    //     )
    //
    //     let connectionURI = """
    //         mongodb+srv://peter:\(password)@barcode-drop.w0gnolp.mongodb.net/Barcodes
    //         """
    //
    //
    //     do {
    //
    //         let x = try await MongoDatabase.connect(to: connectionURI)
    //
    //         let database = try MongoDatabase.lazyConnect(to: connectionURI)
    //         // the connection may still fail even after this method returns
    //         // because it lazily connects when the first operation is executed
    //         print(
    //             "Successfully Lazy-Connected to MongoDB 'Barcodes' database."
    //         )
    //         return database
    //     } catch let connectError {
    //         fatalError(
    //             """
    //             Error connecting to MongoDB (MongoDatabase.lazyConnect): \
    //             \(connectError)
    //             """
    //         )
    //     }
    //
    // }()

    private static var _mongoDatabase: MongoDatabase? = nil

    /// Initializes a connection to the MongoDB database, or returns an existing
    /// connection if one already exists.
    private static func initializeMongoDB() async throws -> MongoDatabase {

        if let database = _mongoDatabase {
            print("Returning existing MongoDB database connection.")
            return database
        }

        print("Initializing MongoDB database connection...")

        guard let password = ProcessInfo.processInfo
                .environment["BARCODE_DROP_DATABASE_PASSWORD"] else {
            fatalError(
                """
                could not retrieve password from BARCODE_DROP_DATABASE_PASSWORD \
                environment variable
                """
            )
        }

        print(
            """
            Retrieved BARCODE_DROP_DATABASE_PASSWORD from the environment \
            variables.
            """
        )

        let connectionURI = """
            mongodb+srv://peter:\(password)@barcode-drop.w0gnolp.mongodb.net/Barcodes
            """

        do {

            // MARK: - Connect to MongoDB Database -
            let database = try await MongoDatabase.connect(
                to: connectionURI
            )

            print(
                "Successfully Connected to MongoDB 'Barcodes' database."
            )

            self._mongoDatabase = database

            return database

        } catch let connectError {
            fatalError(
                """
                Error connecting to MongoDB (MongoDatabase.lazyConnect): \
                \(connectError)
                """
            )
        }

    }

    // In this example we are receiving a SQS Event, with no response (Void).
    func handle(_ event: SQSEvent, context: LambdaContext) async throws {

        for record in event.records {
            print("Received message: \(record.body)")
        }

    }

    /// The entry point for the work that performs all the maintenance tasks
    /// in this lambda.
    func runMaintenance() async throws {
        print("Running maintenance tasks...")

        let database = try await Self.initializeMongoDB()

        let barcodesCollection = database["barcodes"]

        // let olderThanDuration = 300  // 5 minutes
        let olderThanDuration = 1_800  // 30 minutes
        
        print("olderThanDuration: \(olderThanDuration)")

        let currentDate = Date()
        let oldDate = currentDate.addingTimeInterval(
            TimeInterval(-olderThanDuration)
        )
        print(
            """
            Deleting all scans that are older than \(oldDate) \
            (current date: \(currentDate)).
            """
        )

        let deleteResult = try await barcodesCollection.deleteAll(
            where: "date" < oldDate
        )

        print(
            """
            delete result for scans older than \(oldDate): \(deleteResult)
            """
        )

        print("Maintenance tasks completed.")

    }


}

@main
struct Main {
    static func main() async throws {
        print("Testing LambdaHandler: `runMaintenance()`")
        let handler = LambdaHandler()
        try await handler.runMaintenance()

    }
}
