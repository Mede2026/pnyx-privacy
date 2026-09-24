#if !os(watchOS)
import Foundation
import Network
import Security

/// Paramètres réseau communs : Bonjour sur le réseau local, TLS à clé pré-partagée.
public enum MacLinkNetwork {
    public static let serviceType = "_qrstudio._tcp"
    private static let identity = "qrstudio-maclink"

    /// TCP + TLS 1.2 avec la suite PSK : seuls les appareils appairés (même clé) peuvent se parler.
    public static func parameters(key: Data) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let options = tls.securityProtocolOptions
        let psk = key.withUnsafeBytes { DispatchData(bytes: $0) }
        let hint = Data(identity.utf8).withUnsafeBytes { DispatchData(bytes: $0) }
        sec_protocol_options_add_pre_shared_key(options, psk as __DispatchData, hint as __DispatchData)
        if let suite = tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256)) {
            sec_protocol_options_append_tls_ciphersuite(options, suite)
        }
        // Les suites PSK n'existent qu'en TLS 1.2.
        sec_protocol_options_set_min_tls_protocol_version(options, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(options, .TLSv12)

        let tcp = NWProtocolTCP.Options()
        tcp.enableKeepalive = true
        tcp.keepaliveIdle = 10
        let parameters = NWParameters(tls: tls, tcp: tcp)
        parameters.includePeerToPeer = true
        return parameters
    }
}

#endif
