import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import MongoKitten
import Logging

@main
struct BarcodeDropLambdaHandler: LambdaHandler {
    
    typealias Input = ByteBuffer
    typealias Output = Void

    /*
     Environment Variables:
        - BARCODE_DROP_DATABASE_PASSWORD:
            - The password for the MongoDB database.
     */

    static let defaultLogger = Logger(label: "BarcodeDropLambdaHandler")

    private let mongoDatabase: MongoDatabase
    let logger: Logger

    /// Initializes a connection to the MongoDB database
    private static func initializeMongoDB(
        logger: Logger? = nil
    ) async throws -> MongoDatabase {

        let logger = logger ?? Self.defaultLogger

        logger.info("Initializing MongoDB database connection...")

        guard let password = ProcessInfo.processInfo
                .environment["BARCODE_DROP_DATABASE_PASSWORD"] else {
            
            let errorMessage = """
                could not retrieve password from \
                BARCODE_DROP_DATABASE_PASSWORD environment variable
                """
            logger.critical("\(errorMessage)")
            fatalError(errorMessage)

        }

        logger.info(
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

            logger.info(
                "Successfully Connected to MongoDB 'Barcodes' database."
            )

            return database

        } catch let connectError {

            let errorMessage = """
                Error connecting to MongoDB (MongoDatabase.lazyConnect): \
                \(connectError)
                """
            logger.critical("\(errorMessage)")
            fatalError(errorMessage)

        }

    }

    init(context: LambdaInitializationContext) async throws {
        self.logger = context.logger
        self.mongoDatabase = try await Self.initializeMongoDB(
            logger: self.logger
        )
    }   

    func decode(buffer: ByteBuffer) throws -> ByteBuffer {
        return buffer
    }   

    func handle(_ event: Input, context: LambdaContext) async throws {

        let eventString = String(buffer: event)

        self.logger.info(
            """
            LambdaHandler.handle(_:context:): Received event: \(eventString)
            """
        )

        try await self.runMaintenance()

    }

    /// The entry point for the work that performs all the maintenance tasks
    /// in this lambda.
    func runMaintenance() async throws {
        self.logger.info("Running maintenance tasks...")

        let barcodesCollection = self.mongoDatabase["barcodes"]

        // let olderThanDuration = 300  // 5 minutes
        let olderThanDuration = 1_800  // 30 minutes
        
        self.logger.info("olderThanDuration: \(olderThanDuration)")

        let currentDate = Date()
        let oldDate = currentDate.addingTimeInterval(
            TimeInterval(-olderThanDuration)
        )
        self.logger.info(
            """
            Deleting all scans that are older than \(oldDate) \
            (current date: \(currentDate)).
            """
        )

        let deleteResult = try await barcodesCollection.deleteAll(
            where: "date" < oldDate
        )

        self.logger.info(
            """
            delete result for scans older than \(oldDate): \(deleteResult)
            """
        )

        self.logger.info("Maintenance tasks completed.")

    }

}

// @main
// struct Main {
//     static func main() async throws {
//         print("Testing BarcodeDropLambdaHandler: `runMaintenance()`")
//         let handler = BarcodeDropLambdaHandler()
//         try await handler.runMaintenance()
//     }
// }
