import Foundation
import Network
import Testing
@testable import QRCore

/// Connexion réelle en boucle locale : TLS à clé pré-partagée et message ligne par ligne.
@Suite("Liaison chiffrée iPhone ↔ Mac", .serialized)
struct MacLinkNetworkTests {
    /// Démarre un serveur, connecte un client avec `clientKey`, envoie un message et renvoie ce que le serveur a lu.
    private func exchange(serverKey: Data, clientKey: Data, message: MacLinkMessage) async throws -> MacLinkMessage? {
        let queue = DispatchQueue(label: "test.maclink")
        let listener = try NWListener(using: MacLinkNetwork.parameters(key: serverKey), on: .any)
        defer { listener.cancel() }

        let received = AsyncStream<MacLinkMessage?> { continuation in
            listener.newConnectionHandler = { connection in
                connection.start(queue: queue)
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
                    let line = data.flatMap { $0.split(separator: 0x0A).first }.map { Data($0) }
                    continuation.yield(line.flatMap { try? MacLinkMessage.decode(line: $0) })
                    continuation.finish()
                }
            }
        }
        let ready = AsyncStream<UInt16> { continuation in
            listener.stateUpdateHandler = { state in
                if case .ready = state, let port = listener.port?.rawValue {
                    continuation.yield(port)
                    continuation.finish()
                }
            }
        }
        listener.start(queue: queue)
        var port: UInt16 = 0
        for await value in ready { port = value }

        let connection = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port) ?? .any,
                                      using: MacLinkNetwork.parameters(key: clientKey))
        defer { connection.cancel() }
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                let line = (try? message.encodedLine()) ?? Data()
                connection.send(content: line, completion: .idempotent)
            }
        }
        connection.start(queue: queue)

        return await withTaskGroup(of: MacLinkMessage?.self) { group in
            group.addTask {
                for await value in received { return value }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    @Test func sameKeyDeliversTheScan() async throws {
        let pairing = try MacLinkPairing.generate(name: "Mac de test")
        let message = MacLinkMessage(payload: "4006381333931", symbology: "ean13", date: Date(timeIntervalSince1970: 0))
        let received = try await exchange(serverKey: pairing.key, clientKey: pairing.key, message: message)
        #expect(received == message)
    }

    @Test func wrongKeyIsRefused() async throws {
        let server = try MacLinkPairing.generate(name: "Mac")
        let intruder = try MacLinkPairing.generate(name: "Intrus")
        let message = MacLinkMessage(payload: "secret", symbology: "qr")
        let received = try await exchange(serverKey: server.key, clientKey: intruder.key, message: message)
        #expect(received == nil)
    }
}
