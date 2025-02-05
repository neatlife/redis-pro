//
//  ClientsListView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/6/18.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct ClientsListView: View {
    
    var store:Store<ClientListState, ClientListAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: MTheme.V_SPACING) {
                
                NTableView(store: store.scope(state: \.tableState, action: ClientListAction.tableAction))
                
                HStack(alignment: .center , spacing: 8) {
                    Spacer()
                    MButton(text: "Kill Client", action: {viewStore.send(.killConfirm(viewStore.tableState.selectIndex))}, disabled: viewStore.tableState.selectIndex < 0)
                    MButton(text: "Refresh", action: {viewStore.send(.refresh)})
                }
            }
            .onAppear {
                viewStore.send(.initial)
            }
        }
    }
    
}

//struct ClientsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ClientsListView()
//    }
//}
