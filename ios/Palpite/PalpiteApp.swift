import SwiftUI

@main
struct PalpiteApp: App {
    @StateObject private var loja = Loja()
    @Environment(\.scenePhase) private var fase

    var body: some Scene {
        WindowGroup {
            JogoView()
                .environmentObject(loja)
                .preferredColorScheme(.dark)
                .onChange(of: fase) { nova in
                    if nova == .active { loja.conferirNovoDia() }
                }
        }
    }
}
