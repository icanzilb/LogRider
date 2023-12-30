//
//  Siderbar.swift
//  dataFude for Simulator
//
//  Created by Marin Todorov on 4/14/23.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: ConsoleValueModel.ID?
    @EnvironmentObject var sidebarModel: SidebarModel
    var body: some View {
        // Sidebar
        VStack(spacing: 0) {
            Table(sidebarModel.displayTrackedValues, selection: $selectedItem) {
                TableColumn("Name") { item in
                    Text(item.name)
                        .font(.callout.bold().monospaced())
                        .foregroundColor(
                            selectedItem == item.id ? Color.tokenText : .accentColor
                        )
                }
                TableColumn("Value") { item in
                    ConsoleValue(item: item, selectedItem: $selectedItem)
                }
            }
            .padding(0)
            .tableStyle(.automatic)

            SidebarToolbar(model: sidebarModel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 120)
    }
}
