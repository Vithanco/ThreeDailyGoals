import SwiftUI
import tdgCoreWidget

func ShowStatisticsButton(uiState: UIStateManager, dataManager: DataManager) -> some View {

    return Button {
        uiState.showInfo(dataManager.statsOverviewString())
    } label: {
        Label("Statistics", systemImage: imgStats)
    }
    .buttonStyle(PlainButtonStyle())
    .accessibility(label: Text("Show Statistics"))
    .frame(width: 24, height: 24)
}
