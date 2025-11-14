import ConvoUI

enum ChatContextProviderFactory {
    @MainActor
    static func makeDefaultProviders() -> [FinConvoComposerContextProvider] {
        guard #available(iOS 15.0, *) else { return [] }
        return [
            ConvoUIContextProviderBridge(provider: LocationContextProvider()),
            ConvoUIContextProviderBridge(provider: CalendarContextProvider())
        ]
    }
}
